const jwt = require('jsonwebtoken');
const { WebSocket, WebSocketServer } = require('ws');
const { truyVan } = require('./db');

const DUONG_DAN_QUAN_LY = '/api/quan-ly/giam-sat/ws';
const DUONG_DAN_PHU_HUYNH = '/api/phu-huynh/theo-doi/ws';
let kenhDangHoatDong;

function guiTuChoi(socket) {
  socket.end(
    'HTTP/1.1 401 Unauthorized\r\nConnection: close\r\nContent-Length: 0\r\n\r\n',
  );
}

function tuChoiDuongDan(socket) {
  socket.end(
    'HTTP/1.1 404 Not Found\r\nConnection: close\r\nContent-Length: 0\r\n\r\n',
  );
}

function ganKenhGiamSat(server) {
  if (kenhDangHoatDong) {
    throw new Error('Kenh giam sat da duoc gan vao may chu');
  }

  const webSocketServer = new WebSocketServer({ noServer: true, maxPayload: 1024 });
  const xuLyNangCap = async (request, socket, head) => {
    let path;
    let url;
    try {
      url = new URL(request.url, 'http://localhost');
      path = url.pathname;
    } catch (_) {
      socket.destroy();
      return;
    }
    if (path !== DUONG_DAN_QUAN_LY && path !== DUONG_DAN_PHU_HUYNH) {
      tuChoiDuongDan(socket);
      return;
    }

    const authorization = request.headers.authorization || '';
    const token = authorization.startsWith('Bearer ')
      ? authorization.slice(7)
      : null;
    let nguoiDung;
    try {
      if (!token) throw new Error('Thieu token');
      nguoiDung = jwt.verify(token, process.env.JWT_SECRET);
    } catch (_) {
      guiTuChoi(socket);
      return;
    }

    let phuHuynhScope;
    if (path === DUONG_DAN_QUAN_LY) {
      if (nguoiDung.vaiTro !== 'QUAN_LY') {
        guiTuChoi(socket);
        return;
      }
    } else {
      const hocSinhId = url.searchParams.get('hocSinhId');
      if (
        nguoiDung.vaiTro !== 'PHU_HUYNH' ||
        !hocSinhId ||
        !/^[1-9]\d*$/.test(hocSinhId) ||
        !Number.isSafeInteger(Number(hocSinhId))
      ) {
        guiTuChoi(socket);
        return;
      }

      try {
        const ketQua = await truyVan(`
          SELECT cd.id AS chuyen_di_id
          FROM phu_huynh_hoc_sinh phhs
          LEFT JOIN dang_ky_tuyen dk ON dk.hoc_sinh_id = phhs.hoc_sinh_id
          LEFT JOIN chuyen_di cd
            ON cd.tuyen_id = dk.tuyen_id
            AND cd.chieu = dk.chieu
            AND cd.ngay = CURRENT_DATE
          WHERE phhs.phu_huynh_id = $1 AND phhs.hoc_sinh_id = $2
        `, [nguoiDung.id, Number(hocSinhId)]);
        if (ketQua.rows.length === 0) {
          guiTuChoi(socket);
          return;
        }
        phuHuynhScope = {
          phuHuynhId: nguoiDung.id,
          hocSinhId: Number(hocSinhId),
          chuyenIds: new Set(
            ketQua.rows
              .map((row) => Number(row.chuyen_di_id))
              .filter(Number.isSafeInteger),
          ),
        };
      } catch (_) {
        socket.end(
          'HTTP/1.1 503 Service Unavailable\r\nConnection: close\r\nContent-Length: 0\r\n\r\n',
        );
        return;
      }
    }

    if (socket.destroyed) return;
    webSocketServer.handleUpgrade(request, socket, head, (client) => {
      webSocketServer.emit('connection', client, request, phuHuynhScope);
    });
  };

  const ketNoiPhuHuynh = new Map();
  webSocketServer.on('connection', (client, _request, scope) => {
    if (scope) ketNoiPhuHuynh.set(client, scope);
    client.send(JSON.stringify({ type: 'connected' }));
    client.on('close', () => ketNoiPhuHuynh.delete(client));
  });
  server.on('upgrade', xuLyNangCap);

  const kenh = {
    phatCapNhatGps(viTri) {
      return _phatCapNhatGps(viTri, webSocketServer, ketNoiPhuHuynh);
    },
    dong() {
      server.off('upgrade', xuLyNangCap);
      for (const client of webSocketServer.clients) client.terminate();
      return new Promise((resolve) => {
        webSocketServer.close(() => {
          if (kenhDangHoatDong === kenh) kenhDangHoatDong = null;
          resolve();
        });
      });
    },
  };

  kenhDangHoatDong = kenh;
  return kenh;
}

async function _phatCapNhatGps(viTri, webSocketServer, ketNoiPhuHuynh) {
  if (!kenhDangHoatDong) return;
  const thongDiep = JSON.stringify({ type: 'gps_updated', data: viTri });
  for (const client of webSocketServer.clients) {
    if (client.readyState !== WebSocket.OPEN || ketNoiPhuHuynh.has(client)) continue;
    client.send(thongDiep, (error) => {
      if (error) client.terminate();
    });
  }

  if (ketNoiPhuHuynh.size === 0) return;
  let nguoiNhan;
  try {
    const ketQua = await truyVan(`
      SELECT DISTINCT phhs.phu_huynh_id, phhs.hoc_sinh_id
      FROM chuyen_di cd
      JOIN dang_ky_tuyen dk ON dk.tuyen_id = cd.tuyen_id AND dk.chieu = cd.chieu
      JOIN phu_huynh_hoc_sinh phhs ON phhs.hoc_sinh_id = dk.hoc_sinh_id
      WHERE cd.id = $1 AND cd.ngay = CURRENT_DATE
    `, [viTri.chuyen_di_id]);
    nguoiNhan = new Set(
      ketQua.rows.map((row) => `${row.phu_huynh_id}:${row.hoc_sinh_id}`),
    );
  } catch (_) {
    return;
  }

  for (const [client, scope] of ketNoiPhuHuynh) {
    if (
      client.readyState !== WebSocket.OPEN ||
      !scope.chuyenIds.has(Number(viTri.chuyen_di_id)) ||
      !nguoiNhan.has(`${scope.phuHuynhId}:${scope.hocSinhId}`)
    ) {
      continue;
    }
    client.send(thongDiep, (error) => {
      if (error) client.terminate();
    });
  }
}

function phatCapNhatGpsHienTai(viTri) {
  if (!kenhDangHoatDong) return Promise.resolve();
  return kenhDangHoatDong.phatCapNhatGps(viTri);
}

module.exports = {
  ganKenhGiamSat,
  phatCapNhatGps: phatCapNhatGpsHienTai,
};
