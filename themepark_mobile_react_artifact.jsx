import React, { useEffect, useMemo, useRef, useState } from "react";

const MAP_SIZE = 20;
const TILE_W = 64;
const TILE_H = 32;
const MIN_ZOOM = 0.6;
const MAX_ZOOM = 2.2;

const BUILDINGS = {
  rollercoaster: {
    id: "rollercoaster",
    name: "롤러코스터",
    emoji: "🎢",
    category: "ride",
    cost: 3000,
    maintenance: 50,
    capacity: 20,
    fun: 18,
    shopIncome: 0,
  },
  carousel: {
    id: "carousel",
    name: "회전목마",
    emoji: "🎠",
    category: "ride",
    cost: 1000,
    maintenance: 20,
    capacity: 10,
    fun: 10,
    shopIncome: 0,
  },
  viking: {
    id: "viking",
    name: "바이킹",
    emoji: "🏴‍☠️",
    category: "ride",
    cost: 2000,
    maintenance: 35,
    capacity: 15,
    fun: 15,
    shopIncome: 0,
  },
  burger: {
    id: "burger",
    name: "햄버거 가게",
    emoji: "🍔",
    category: "shop",
    cost: 500,
    maintenance: 10,
    capacity: 0,
    fun: 0,
    shopIncome: 30,
  },
  drink: {
    id: "drink",
    name: "음료수 가게",
    emoji: "🥤",
    category: "shop",
    cost: 400,
    maintenance: 8,
    capacity: 0,
    fun: 0,
    shopIncome: 25,
  },
  restroom: {
    id: "restroom",
    name: "화장실",
    emoji: "🚻",
    category: "utility",
    cost: 300,
    maintenance: 15,
    capacity: 0,
    fun: 0,
    satisfactionBonus: 8,
    shopIncome: 0,
  },
  path: {
    id: "path",
    name: "길",
    emoji: "🟫",
    category: "path",
    cost: 10,
    maintenance: 0,
    capacity: 0,
    fun: 0,
    shopIncome: 0,
  },
};

const CATEGORIES = [
  { id: "ride", label: "놀이기구", icon: "🎡" },
  { id: "shop", label: "매점", icon: "🏪" },
  { id: "utility", label: "편의시설", icon: "🧰" },
  { id: "path", label: "길", icon: "🛣️" },
];

const initialTiles = () => {
  const grid = Array.from({ length: MAP_SIZE }, () =>
    Array.from({ length: MAP_SIZE }, () => ({ type: "grass", facilityId: null }))
  );

  const mid = Math.floor(MAP_SIZE / 2);
  for (let y = mid - 2; y <= mid + 2; y++) {
    grid[mid][y] = { type: "path", facilityId: null };
  }
  return grid;
};

const keyOf = (x, y) => `${x},${y}`;
const clamp = (v, min, max) => Math.max(min, Math.min(max, v));

const isoToScreen = (x, y) => ({
  x: (x - y) * (TILE_W / 2),
  y: (x + y) * (TILE_H / 2),
});

const screenToIso = (px, py, camX, camY, zoom) => {
  const wx = (px - camX) / zoom;
  const wy = (py - camY) / zoom;
  const ix = (wy / (TILE_H / 2) + wx / (TILE_W / 2)) / 2;
  const iy = (wy / (TILE_H / 2) - wx / (TILE_W / 2)) / 2;
  return { x: Math.floor(ix), y: Math.floor(iy) };
};

export default function IsometricThemeParkMobile() {
  const [tiles, setTiles] = useState(initialTiles);
  const [money, setMoney] = useState(10000);
  const [visitors, setVisitors] = useState([]);
  const [rating, setRating] = useState(50);
  const [running, setRunning] = useState(true);
  const [speed, setSpeed] = useState(1);
  const [gameMinutes, setGameMinutes] = useState(8 * 60);

  const [activeCategory, setActiveCategory] = useState("ride");
  const [selectedBuild, setSelectedBuild] = useState("rollercoaster");
  const [hoverTile, setHoverTile] = useState(null);
  const [placeValid, setPlaceValid] = useState(true);

  const [cam, setCam] = useState({ x: 420, y: 90, zoom: 1 });

  const viewportRef = useRef(null);
  const gestureRef = useRef({
    mode: null,
    startX: 0,
    startY: 0,
    startCamX: 0,
    startCamY: 0,
    startDist: 0,
    startZoom: 1,
  });
  const visitorIdRef = useRef(1);

  const builtFacilities = useMemo(() => {
    const list = [];
    for (let x = 0; x < MAP_SIZE; x++) {
      for (let y = 0; y < MAP_SIZE; y++) {
        const t = tiles[x][y];
        if (t.type === "facility" && t.facilityId) {
          const b = BUILDINGS[t.facilityId];
          if (b) list.push({ ...b, x, y });
        }
      }
    }
    return list;
  }, [tiles]);

  const pathSet = useMemo(() => {
    const s = new Set();
    for (let x = 0; x < MAP_SIZE; x++) {
      for (let y = 0; y < MAP_SIZE; y++) {
        if (tiles[x][y].type === "path") s.add(keyOf(x, y));
      }
    }
    return s;
  }, [tiles]);

  const parkAttractiveness = useMemo(() => {
    const rideFun = builtFacilities
      .filter((f) => f.category === "ride")
      .reduce((a, b) => a + b.fun, 0);
    const amenityBonus = builtFacilities
      .filter((f) => f.id === "restroom")
      .reduce((a, b) => a + (b.satisfactionBonus || 0), 0);
    return rideFun + amenityBonus + Math.min(visitors.length, 80) * 0.25;
  }, [builtFacilities, visitors.length]);

  const avgSatisfaction = useMemo(() => {
    if (!visitors.length) return 50;
    return visitors.reduce((sum, v) => sum + v.satisfaction, 0) / visitors.length;
  }, [visitors]);

  useEffect(() => {
    const value = clamp(
      Math.round(0.55 * avgSatisfaction + 0.45 * Math.min(100, parkAttractiveness)),
      0,
      100
    );
    setRating(value);
  }, [avgSatisfaction, parkAttractiveness]);

  useEffect(() => {
    if (!running) return;
    const interval = setInterval(() => {
      tickOneMinute();
    }, 1000 / speed);
    return () => clearInterval(interval);
  }, [running, speed, tiles, visitors, builtFacilities, parkAttractiveness]);

  const tickOneMinute = () => {
    setGameMinutes((m) => (m + 1) % (24 * 60));

    const maintenance = builtFacilities.reduce((sum, f) => sum + (f.maintenance || 0), 0);
    const passiveShopIncome = builtFacilities.reduce((sum, f) => sum + (f.shopIncome || 0), 0);

    const spawnChance = clamp(0.06 + parkAttractiveness / 280, 0.06, 0.35);
    let spawned = false;

    setVisitors((prev) => {
      let next = [...prev];

      if (Math.random() < spawnChance && pathSet.size > 0 && prev.length < 240) {
        const entry = [...pathSet][Math.floor(Math.random() * pathSet.size)];
        const [ex, ey] = entry.split(",").map(Number);
        next.push({
          id: visitorIdRef.current++,
          x: ex,
          y: ey,
          satisfaction: clamp(55 + Math.random() * 20, 0, 100),
          mood: "🙂",
        });
        spawned = true;
      }

      next = next
        .map((v) => {
          const dirs = [
            [1, 0],
            [-1, 0],
            [0, 1],
            [0, -1],
          ];
          const candidates = dirs
            .map(([dx, dy]) => ({ x: v.x + dx, y: v.y + dy }))
            .filter(
              (p) =>
                p.x >= 0 &&
                p.x < MAP_SIZE &&
                p.y >= 0 &&
                p.y < MAP_SIZE &&
                pathSet.has(keyOf(p.x, p.y))
            );

          let nx = v.x;
          let ny = v.y;
          if (candidates.length) {
            const pick = candidates[Math.floor(Math.random() * candidates.length)];
            nx = pick.x;
            ny = pick.y;
          }

          let satDelta = -0.4;
          let mood = "😐";

          for (const [dx, dy] of dirs) {
            const tx = nx + dx;
            const ty = ny + dy;
            if (tx < 0 || ty < 0 || tx >= MAP_SIZE || ty >= MAP_SIZE) continue;
            const t = tiles[tx][ty];
            if (t.type === "facility" && t.facilityId) {
              const b = BUILDINGS[t.facilityId];
              if (!b) continue;
              if (b.category === "ride" && Math.random() < 0.16) {
                satDelta += 5 + b.fun * 0.25;
              } else if (b.category === "shop" && Math.random() < 0.12) {
                satDelta += 2.8;
              } else if (b.id === "restroom" && Math.random() < 0.08) {
                satDelta += 3.5;
              }
            }
          }

          const newSat = clamp(v.satisfaction + satDelta, 0, 100);
          if (newSat > 75) mood = "😄";
          else if (newSat > 55) mood = "🙂";
          else if (newSat > 35) mood = "😐";
          else mood = "😣";

          return { ...v, x: nx, y: ny, satisfaction: newSat, mood };
        })
        .filter((v) => v.satisfaction > 8 || Math.random() > 0.15);

      return next;
    });

    const activityIncome = Math.round(visitors.length * 1.4 + parkAttractiveness * 0.2);
    const delta = passiveShopIncome + activityIncome - maintenance;
    setMoney((m) => m + delta);

    if (!spawned && visitors.length < 5 && Math.random() < 0.25) {
      setVisitors((v) => v.slice(0, Math.max(0, v.length - 1)));
    }
  };

  const buildingOptions = useMemo(
    () => Object.values(BUILDINGS).filter((b) => b.category === activeCategory),
    [activeCategory]
  );

  useEffect(() => {
    const options = Object.values(BUILDINGS).filter((b) => b.category === activeCategory);
    if (!options.find((o) => o.id === selectedBuild)) {
      setSelectedBuild(options[0]?.id || "path");
    }
  }, [activeCategory, selectedBuild]);

  const isInside = (x, y) => x >= 0 && y >= 0 && x < MAP_SIZE && y < MAP_SIZE;

  const hasAdjacentPath = (x, y) => {
    const dirs = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ];
    return dirs.some(([dx, dy]) => {
      const nx = x + dx;
      const ny = y + dy;
      return isInside(nx, ny) && tiles[nx][ny].type === "path";
    });
  };

  const canPlaceAt = (x, y, buildId) => {
    if (!isInside(x, y)) return false;
    const tile = tiles[x][y];
    const b = BUILDINGS[buildId];
    if (!b) return false;
    if (money < b.cost) return false;

    if (b.id === "path") return tile.type === "grass";
    return tile.type === "grass" && hasAdjacentPath(x, y);
  };

  const placeBuilding = (x, y) => {
    const b = BUILDINGS[selectedBuild];
    if (!b || !canPlaceAt(x, y, selectedBuild)) return;

    setTiles((prev) => {
      const next = prev.map((row) => row.slice());
      if (selectedBuild === "path") next[x][y] = { type: "path", facilityId: null };
      else next[x][y] = { type: "facility", facilityId: selectedBuild };
      return next;
    });

    setMoney((m) => m - b.cost);
  };

  const handlePointerDown = (e) => {
    if (!viewportRef.current) return;
    const rect = viewportRef.current.getBoundingClientRect();

    if (e.touches && e.touches.length === 2) {
      const [t1, t2] = e.touches;
      const dx = t2.clientX - t1.clientX;
      const dy = t2.clientY - t1.clientY;
      const dist = Math.hypot(dx, dy);

      gestureRef.current = {
        mode: "pinch",
        startDist: dist,
        startZoom: cam.zoom,
        startCamX: cam.x,
        startCamY: cam.y,
      };
      return;
    }

    const p = e.touches ? e.touches[0] : e;
    gestureRef.current = {
      mode: "drag",
      startX: p.clientX,
      startY: p.clientY,
      startCamX: cam.x,
      startCamY: cam.y,
    };

    const tile = screenToIso(p.clientX - rect.left, p.clientY - rect.top, cam.x, cam.y, cam.zoom);
    if (isInside(tile.x, tile.y)) {
      setHoverTile(tile);
      setPlaceValid(canPlaceAt(tile.x, tile.y, selectedBuild));
    }
  };

  const handlePointerMove = (e) => {
    if (!viewportRef.current) return;
    const rect = viewportRef.current.getBoundingClientRect();

    if (e.touches && e.touches.length === 2 && gestureRef.current.mode === "pinch") {
      e.preventDefault();
      const [t1, t2] = e.touches;
      const dist = Math.hypot(t2.clientX - t1.clientX, t2.clientY - t1.clientY);
      const ratio = dist / (gestureRef.current.startDist || dist);
      const newZoom = clamp(gestureRef.current.startZoom * ratio, MIN_ZOOM, MAX_ZOOM);
      setCam((prev) => ({ ...prev, zoom: newZoom }));
      return;
    }

    const p = e.touches ? e.touches[0] : e;

    if (gestureRef.current.mode === "drag") {
      const dx = p.clientX - gestureRef.current.startX;
      const dy = p.clientY - gestureRef.current.startY;
      setCam((prev) => ({
        ...prev,
        x: gestureRef.current.startCamX + dx,
        y: gestureRef.current.startCamY + dy,
      }));
    }

    const tile = screenToIso(p.clientX - rect.left, p.clientY - rect.top, cam.x, cam.y, cam.zoom);
    if (isInside(tile.x, tile.y)) {
      setHoverTile(tile);
      setPlaceValid(canPlaceAt(tile.x, tile.y, selectedBuild));
    } else {
      setHoverTile(null);
      setPlaceValid(false);
    }
  };

  const handlePointerUp = (e) => {
    if (!viewportRef.current) return;
    const rect = viewportRef.current.getBoundingClientRect();
    const p = e.changedTouches ? e.changedTouches[0] : e;

    const tapTile = screenToIso(
      p.clientX - rect.left,
      p.clientY - rect.top,
      cam.x,
      cam.y,
      cam.zoom
    );

    if (isInside(tapTile.x, tapTile.y)) {
      const moved =
        Math.hypot(
          p.clientX - (gestureRef.current.startX || p.clientX),
          p.clientY - (gestureRef.current.startY || p.clientY)
        ) > 8;
      if (!moved && gestureRef.current.mode !== "pinch") placeBuilding(tapTile.x, tapTile.y);
    }

    gestureRef.current.mode = null;
  };

  const timeLabel = useMemo(() => {
    const h = String(Math.floor(gameMinutes / 60)).padStart(2, "0");
    const m = String(gameMinutes % 60).padStart(2, "0");
    return `${h}:${m}`;
  }, [gameMinutes]);

  return (
    <div className="h-screen w-full bg-gradient-to-b from-amber-50 to-lime-100 text-slate-800 flex flex-col overflow-hidden select-none">
      <header className="px-3 pt-3 pb-2 z-20">
        <div className="rounded-2xl bg-white/90 backdrop-blur shadow-md p-2.5">
          <div className="grid grid-cols-3 gap-2 text-center text-sm">
            <div className="rounded-xl bg-emerald-50 p-2 min-h-[44px] flex flex-col justify-center">
              <div className="text-[11px] text-emerald-700">자금</div>
              <div className="font-bold text-emerald-800">₩ {money.toLocaleString()}</div>
            </div>
            <div className="rounded-xl bg-sky-50 p-2 min-h-[44px] flex flex-col justify-center">
              <div className="text-[11px] text-sky-700">방문객</div>
              <div className="font-bold text-sky-800">{visitors.length}명</div>
            </div>
            <div className="rounded-xl bg-amber-50 p-2 min-h-[44px] flex flex-col justify-center">
              <div className="text-[11px] text-amber-700">공원 평점</div>
              <div className="font-bold text-amber-800">{rating} / 100</div>
            </div>
          </div>

          <div className="flex items-center justify-between mt-2">
            <div className="text-xs font-medium text-slate-600">🕒 {timeLabel}</div>
            <div className="flex gap-2">
              <button
                className={`min-w-[44px] min-h-[44px] px-3 rounded-xl text-sm font-semibold ${
                  running ? "bg-slate-100" : "bg-slate-800 text-white"
                }`}
                onClick={() => setRunning((v) => !v)}
              >
                {running ? "⏸" : "▶"}
              </button>
              <button
                className={`min-w-[44px] min-h-[44px] px-3 rounded-xl text-sm font-semibold ${
                  speed === 1 ? "bg-violet-100 text-violet-800" : "bg-violet-600 text-white"
                }`}
                onClick={() => setSpeed((s) => (s === 1 ? 2 : 1))}
              >
                {speed}x
              </button>
            </div>
          </div>
        </div>
      </header>

      <main className="flex-1 px-2 pb-2 relative">
        <div
          ref={viewportRef}
          className="h-full w-full rounded-2xl bg-lime-200/80 shadow-inner border border-white/70 overflow-hidden touch-none relative"
          onMouseDown={handlePointerDown}
          onMouseMove={handlePointerMove}
          onMouseUp={handlePointerUp}
          onTouchStart={handlePointerDown}
          onTouchMove={handlePointerMove}
          onTouchEnd={handlePointerUp}
        >
          <div
            className="absolute left-0 top-0"
            style={{
              transform: `translate(${cam.x}px, ${cam.y}px) scale(${cam.zoom})`,
              transformOrigin: "0 0",
              willChange: "transform",
            }}
          >
            {Array.from({ length: MAP_SIZE }).map((_, x) =>
              Array.from({ length: MAP_SIZE }).map((__, y) => {
                const tile = tiles[x][y];
                const pos = isoToScreen(x, y);
                const bg =
                  tile.type === "grass"
                    ? "bg-lime-400"
                    : tile.type === "path"
                    ? "bg-amber-200"
                    : "bg-lime-300";

                return (
                  <div
                    key={`${x}-${y}`}
                    className={`absolute ${bg} border border-white/45`}
                    style={{
                      width: TILE_W,
                      height: TILE_H,
                      left: pos.x - TILE_W / 2,
                      top: pos.y - TILE_H / 2,
                      transform: "skewY(-26.565deg) scaleY(0.5)",
                      borderRadius: 2,
                      boxSizing: "border-box",
                      boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.2)",
                    }}
                  />
                );
              })
            )}

            {builtFacilities.map((f) => {
              const pos = isoToScreen(f.x, f.y);
              return (
                <div
                  key={`f-${f.x}-${f.y}`}
                  className="absolute text-2xl drop-shadow-md"
                  style={{ left: pos.x - 12, top: pos.y - 32, transform: "translateZ(0)" }}
                >
                  {f.emoji}
                </div>
              );
            })}

            {visitors.map((v) => {
              const pos = isoToScreen(v.x, v.y);
              return (
                <div
                  key={v.id}
                  className="absolute transition-all duration-500 ease-linear"
                  style={{ left: pos.x - 6, top: pos.y - 12, transform: "translateZ(0)" }}
                >
                  <div className="w-3 h-3 rounded-full bg-sky-600 border border-white shadow" />
                </div>
              );
            })}

            {hoverTile && isInside(hoverTile.x, hoverTile.y) && (() => {
              const pos = isoToScreen(hoverTile.x, hoverTile.y);
              return (
                <div
                  className={`absolute border-2 ${
                    placeValid ? "border-emerald-500/80" : "border-red-500/90"
                  }`}
                  style={{
                    width: TILE_W,
                    height: TILE_H,
                    left: pos.x - TILE_W / 2,
                    top: pos.y - TILE_H / 2,
                    transform: "skewY(-26.565deg) scaleY(0.5)",
                    borderRadius: 2,
                    pointerEvents: "none",
                  }}
                />
              );
            })()}
          </div>

          <div className="absolute left-2 top-2 text-[11px] bg-white/80 rounded-lg px-2 py-1">
            드래그: 이동 · 핀치: 줌 · 탭: 건설
          </div>
        </div>
      </main>

      <footer className="px-2 pb-2 z-20">
        <div className="rounded-2xl bg-white/95 shadow-lg p-2">
          <div className="grid grid-cols-4 gap-2 mb-2">
            {CATEGORIES.map((cat) => (
              <button
                key={cat.id}
                onClick={() => setActiveCategory(cat.id)}
                className={`min-h-[44px] rounded-xl text-xs font-semibold flex items-center justify-center gap-1 ${
                  activeCategory === cat.id
                    ? "bg-slate-800 text-white"
                    : "bg-slate-100 text-slate-700"
                }`}
              >
                <span>{cat.icon}</span>
                <span>{cat.label}</span>
              </button>
            ))}
          </div>

          <div className="flex gap-2 overflow-x-auto pb-1">
            {buildingOptions.map((b) => (
              <button
                key={b.id}
                onClick={() => setSelectedBuild(b.id)}
                className={`min-w-[120px] min-h-[64px] rounded-xl px-2 py-1 text-left border ${
                  selectedBuild === b.id
                    ? "border-violet-500 bg-violet-50"
                    : "border-slate-200 bg-white"
                }`}
              >
                <div className="flex items-center gap-1.5">
                  <span className="text-xl">{b.emoji}</span>
                  <span className="font-semibold text-sm">{b.name}</span>
                </div>
                <div className="text-[11px] text-slate-600 mt-0.5">건설 ₩{b.cost.toLocaleString()}</div>
                {b.maintenance > 0 && (
                  <div className="text-[11px] text-rose-600">유지 -₩{b.maintenance}/분</div>
                )}
                {b.shopIncome > 0 && (
                  <div className="text-[11px] text-emerald-600">수익 +₩{b.shopIncome}/분</div>
                )}
              </button>
            ))}
          </div>
        </div>
      </footer>
    </div>
  );
}
