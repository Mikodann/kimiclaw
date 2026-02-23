// RCT-style theme park game core (renderer-agnostic)
// Keeps simulation logic separate from UI/rendering (React/Pixi/Canvas/etc.)

export const MAP_SIZE = 20;

export const BUILDINGS = {
  rollercoaster: { id: "rollercoaster", name: "롤러코스터", category: "ride", cost: 3000, maintenance: 50, fun: 18, shopIncome: 0 },
  carousel: { id: "carousel", name: "회전목마", category: "ride", cost: 1000, maintenance: 20, fun: 10, shopIncome: 0 },
  viking: { id: "viking", name: "바이킹", category: "ride", cost: 2000, maintenance: 35, fun: 15, shopIncome: 0 },
  ferris: { id: "ferris", name: "대관람차", category: "ride", cost: 2600, maintenance: 40, fun: 14, shopIncome: 0, lockedByResearch: true },
  bumper: { id: "bumper", name: "범퍼카", category: "ride", cost: 1800, maintenance: 30, fun: 13, shopIncome: 0, lockedByResearch: true },
  waterslide: { id: "waterslide", name: "워터슬라이드", category: "ride", cost: 3400, maintenance: 55, fun: 20, shopIncome: 0, lockedByResearch: true },
  burger: { id: "burger", name: "햄버거", category: "shop", cost: 500, maintenance: 10, fun: 0, shopIncome: 30 },
  drink: { id: "drink", name: "음료수", category: "shop", cost: 400, maintenance: 8, fun: 0, shopIncome: 25 },
  restroom: { id: "restroom", name: "화장실", category: "utility", cost: 300, maintenance: 15, fun: 0, shopIncome: 0 },
  path: { id: "path", name: "길", category: "path", cost: 10, maintenance: 0, fun: 0, shopIncome: 0 },
};

const clamp = (v, min, max) => Math.max(min, Math.min(max, v));
const keyOf = (x, y) => `${x},${y}`;

export function createInitialTiles() {
  const grid = Array.from({ length: MAP_SIZE }, () =>
    Array.from({ length: MAP_SIZE }, () => ({ type: "grass", facilityId: null }))
  );
  const mid = Math.floor(MAP_SIZE / 2);
  for (let y = mid - 2; y <= mid + 2; y++) grid[mid][y] = { type: "path", facilityId: null };
  return grid;
}

export function createInitialGameState() {
  return {
    tiles: createInitialTiles(),
    money: 10000,
    visitors: [],
    facilityMeta: {},
    unlockedRides: ["rollercoaster", "carousel", "viking"],
    activeEvent: { name: "맑음", visitorMult: 1, satDelta: 0, minutesLeft: 0 },
    gameMinutes: 8 * 60,
    maxVisitors: 0,
    rating: 50,
    entryFee: 100,
    nextVisitorId: 1,
    lastTickIncome: 0,
    lastTickExpense: 0,
  };
}

export function isoToScreen(x, y, tileW = 64, tileH = 32) {
  return {
    x: (x - y) * (tileW / 2),
    y: (x + y) * (tileH / 2),
  };
}

export function screenToIso(px, py, camX, camY, zoom, tileW = 64, tileH = 32) {
  const wx = (px - camX) / zoom;
  const wy = (py - camY) / zoom;
  const ix = (wy / (tileH / 2) + wx / (tileW / 2)) / 2;
  const iy = (wy / (tileH / 2) - wx / (tileW / 2)) / 2;
  return { x: Math.floor(ix), y: Math.floor(iy) };
}

function isInside(x, y) {
  return x >= 0 && y >= 0 && x < MAP_SIZE && y < MAP_SIZE;
}

function buildPathSet(tiles) {
  const set = new Set();
  for (let x = 0; x < MAP_SIZE; x++) {
    for (let y = 0; y < MAP_SIZE; y++) {
      if (tiles[x][y].type === "path") set.add(keyOf(x, y));
    }
  }
  return set;
}

function builtFacilitiesOf(state) {
  const out = [];
  for (let x = 0; x < MAP_SIZE; x++) {
    for (let y = 0; y < MAP_SIZE; y++) {
      const t = state.tiles[x][y];
      if (t.type !== "facility" || !t.facilityId) continue;
      const b = BUILDINGS[t.facilityId];
      if (!b) continue;
      const k = keyOf(x, y);
      out.push({ ...b, x, y, key: k, meta: state.facilityMeta[k] || { level: 1, users: 0, revenue: 0, broken: false } });
    }
  }
  return out;
}

function hasAdjacentPath(tiles, x, y) {
  return [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => {
    const nx = x + dx;
    const ny = y + dy;
    return isInside(nx, ny) && tiles[nx][ny].type === "path";
  });
}

export function canPlaceAt(state, x, y, buildingId) {
  if (!isInside(x, y)) return false;
  const b = BUILDINGS[buildingId];
  if (!b || state.money < b.cost) return false;
  const tile = state.tiles[x][y];
  if (buildingId === "path") return tile.type === "grass";
  return tile.type === "grass" && hasAdjacentPath(state.tiles, x, y);
}

export function placeBuilding(state, x, y, buildingId) {
  if (!canPlaceAt(state, x, y, buildingId)) return state;
  const next = structuredClone(state);
  const b = BUILDINGS[buildingId];
  next.money -= b.cost;
  if (buildingId === "path") next.tiles[x][y] = { type: "path", facilityId: null };
  else {
    next.tiles[x][y] = { type: "facility", facilityId: buildingId };
    next.facilityMeta[keyOf(x, y)] = { level: 1, users: 0, revenue: 0, broken: false };
  }
  return next;
}

export function tickOneMinute(prev) {
  const state = structuredClone(prev);
  state.gameMinutes = (state.gameMinutes + 1) % (24 * 60);

  const facilities = builtFacilitiesOf(state);
  const pathSet = buildPathSet(state.tiles);

  // random breakdown (facility-level weighted)
  for (const f of facilities) {
    const chance = 0.015 / Math.max(1, f.meta.level || 1);
    if (Math.random() < chance && !f.meta.broken) {
      state.facilityMeta[f.key] = { ...f.meta, broken: true };
      break;
    }
  }

  const rideFun = facilities
    .filter((f) => f.category === "ride")
    .reduce((sum, f) => sum + f.fun + (f.meta.level - 1) * 4, 0);

  const spawnChance = clamp((0.06 + rideFun / 280) * state.activeEvent.visitorMult * (1 - state.entryFee / 2000), 0.03, 0.45);

  if (Math.random() < spawnChance && pathSet.size > 0 && state.visitors.length < 260) {
    const [ex, ey] = [...pathSet][Math.floor(Math.random() * pathSet.size)].split(",").map(Number);
    state.visitors.push({ id: state.nextVisitorId++, x: ex, y: ey, satisfaction: clamp(55 + Math.random() * 20, 0, 100) });
  }

  const dirs = [[1, 0], [-1, 0], [0, 1], [0, -1]];
  const usage = {};

  state.visitors = state.visitors
    .map((v) => {
      const candidates = dirs
        .map(([dx, dy]) => ({ x: v.x + dx, y: v.y + dy }))
        .filter((p) => isInside(p.x, p.y) && pathSet.has(keyOf(p.x, p.y)));

      let nx = v.x;
      let ny = v.y;
      if (candidates.length) {
        const weighted = candidates.map((p) => {
          let w = 1;
          for (const [adx, ady] of dirs) {
            const ax = p.x + adx;
            const ay = p.y + ady;
            if (!isInside(ax, ay)) continue;
            const tile = state.tiles[ax][ay];
            if (tile.type === "facility" && tile.facilityId) {
              const meta = state.facilityMeta[keyOf(ax, ay)] || { broken: false };
              if (!meta.broken) w += 2;
            }
          }
          return { ...p, w };
        });
        const total = weighted.reduce((a, c) => a + c.w, 0);
        let r = Math.random() * total;
        let pick = weighted[0];
        for (const c of weighted) {
          r -= c.w;
          if (r <= 0) {
            pick = c;
            break;
          }
        }
        nx = pick.x;
        ny = pick.y;
      }

      let satDelta = -0.4 + state.activeEvent.satDelta - state.entryFee / 1200;
      for (const [dx, dy] of dirs) {
        const tx = nx + dx;
        const ty = ny + dy;
        if (!isInside(tx, ty)) continue;
        const t = state.tiles[tx][ty];
        if (t.type !== "facility" || !t.facilityId) continue;
        const b = BUILDINGS[t.facilityId];
        const fk = keyOf(tx, ty);
        const meta = state.facilityMeta[fk] || { level: 1, broken: false };
        if (meta.broken) continue;
        if (b.category === "ride" && Math.random() < 0.17) {
          satDelta += 4 + b.fun * 0.22 + (meta.level - 1) * 1.4;
          usage[fk] = (usage[fk] || 0) + 1;
        }
        if (b.category === "shop" && Math.random() < 0.12) {
          satDelta += 2.2;
          usage[fk] = (usage[fk] || 0) + 1;
        }
      }
      return { ...v, x: nx, y: ny, satisfaction: clamp(v.satisfaction + satDelta, 0, 100) };
    })
    .filter((v) => v.satisfaction > 8 || Math.random() > 0.15);

  for (const k of Object.keys(usage)) {
    const p = state.facilityMeta[k] || { level: 1, users: 0, revenue: 0, broken: false };
    state.facilityMeta[k] = { ...p, users: (p.users || 0) + usage[k] };
  }

  state.maxVisitors = Math.max(state.maxVisitors, state.visitors.length);

  const maintenance = facilities.reduce((sum, f) => {
    const lvl = f.meta.level || 1;
    return sum + Math.round((f.maintenance || 0) * (1 + (lvl - 1) * 0.2));
  }, 0);

  const shopIncome = facilities.reduce((sum, f) => {
    if (f.meta.broken) return sum;
    const lvl = f.meta.level || 1;
    return sum + Math.round((f.shopIncome || 0) * (1 + (lvl - 1) * 0.25));
  }, 0);

  const entranceIncome = Math.round(state.visitors.length * state.entryFee * 0.2);
  const activityIncome = Math.round(state.visitors.length * 1.3 + rideFun * 0.2 * state.activeEvent.visitorMult);

  state.lastTickIncome = shopIncome + entranceIncome + activityIncome;
  state.lastTickExpense = maintenance;
  state.money += state.lastTickIncome - state.lastTickExpense;

  const avgSat = state.visitors.length
    ? state.visitors.reduce((s, v) => s + v.satisfaction, 0) / state.visitors.length
    : 50;
  state.rating = clamp(Math.round(0.45 * avgSat + 0.35 * Math.min(100, rideFun) + 20), 0, 100);

  return state;
}
