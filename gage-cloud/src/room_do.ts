/**
 * GAGE Tracking Room — Cloudflare Durable Object
 * Mengelola siaran lokasi GPS Driver secara ephemeral via WebSocket.
 * 100% Zero-Write ke Cloudflare D1 untuk menjaga batas gratisan (Free Tier).
 */

export interface LocationPayload {
  token: string;
  driverId: string;
  lat: number;
  lng: number;
  heading?: number;
  speed?: number;
  updatedAt: number;
}

export class TrackingRoomDO {
  private state: DurableObjectState;
  private sessions: Map<WebSocket, { token: string; role: 'driver' | 'viewer' }> = new Map();
  private lastKnownLocations: Map<string, LocationPayload> = new Map();

  constructor(state: DurableObjectState) {
    this.state = state;
  }

  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    // 1. WebSocket Upgrade Endpoint: /ws?token=XXX&role=driver|viewer
    if (request.headers.get('Upgrade') === 'websocket') {
      const token = url.searchParams.get('token') || '';
      const role = (url.searchParams.get('role') || 'viewer') as 'driver' | 'viewer';

      if (!token) {
        return new Response('Token tracking order wajib diisi', { status: 400 });
      }

      const pair = new WebSocketPair();
      const [client, server] = [pair[0], pair[1]];

      await this.handleSession(server, token, role);

      return new Response(null, {
        status: 101,
        webSocket: client,
      });
    }

    // 2. HTTP Fallback Endpoint untuk mendapatkan lokasi terakhir tanpa WebSocket
    // GET /location?token=XXX
    if (url.pathname === '/location') {
      const token = url.searchParams.get('token') || '';
      const loc = this.lastKnownLocations.get(token);
      if (!loc) {
        return new Response(JSON.stringify({ success: false, message: 'Belum ada data lokasi aktif' }), {
          status: 404,
          headers: { 'Content-Type': 'application/json' },
        });
      }
      return new Response(JSON.stringify({ success: true, data: loc }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    return new Response('Not Found', { status: 404 });
  }

  private async handleSession(ws: WebSocket, token: string, role: 'driver' | 'viewer') {
    ws.accept();
    this.sessions.set(ws, { token, role });

    // Jika ada viewer baru masuk dan sudah ada lokasi driver terakhir, langsung kirimkan
    if (role === 'viewer') {
      const lastLoc = this.lastKnownLocations.get(token);
      if (lastLoc) {
        ws.send(JSON.stringify({ type: 'LOCATION_UPDATE', data: lastLoc }));
      }
    }

    ws.addEventListener('message', (event) => {
      try {
        const msg = JSON.parse(event.data as string);

        // Driver mengirim update GPS koordinat
        if (msg.type === 'PING_LOCATION' && role === 'driver') {
          const payload: LocationPayload = {
            token,
            driverId: msg.driverId || 'unknown',
            lat: Number(msg.lat),
            lng: Number(msg.lng),
            heading: msg.heading ? Number(msg.heading) : undefined,
            speed: msg.speed ? Number(msg.speed) : undefined,
            updatedAt: Math.floor(Date.now() / 1000),
          };

          // Simpan di memori ephemeral DO
          this.lastKnownLocations.set(token, payload);

          // Siarkan ke seluruh penonton (viewer) yang memantau token pesanan ini
          const broadcastMsg = JSON.stringify({ type: 'LOCATION_UPDATE', data: payload });
          for (const [clientWs, session] of this.sessions.entries()) {
            if (session.token === token && session.role === 'viewer' && clientWs.readyState === WebSocket.READY_STATE_OPEN) {
              clientWs.send(broadcastMsg);
            }
          }
        }
      } catch (err) {
        console.error('Error parsing WebSocket message:', err);
      }
    });

    const cleanup = () => {
      this.sessions.delete(ws);
    };

    ws.addEventListener('close', cleanup);
    ws.addEventListener('error', cleanup);
  }
}
