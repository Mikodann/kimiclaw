import React, { useEffect, useMemo, useRef, useState } from "react";

const MAP_SIZE = 20;
const TILE_W = 64;
const TILE_H = 32;
const MIN_ZOOM = 0.6;
const MAX_ZOOM = 2.2;

const BUILDINGS = {
  rollercoaster: { id: "rollercoaster", name: "롤러코스터", emoji: "🎢", category: "ride", cost: 3000, maintenance: 50, capacity: 20, fun: 18, shopIncome: 0 },
  carousel: { id: "carousel", name: "회전목마", emoji: "🎠", category: "ride", cost: 1000, maintenance: 20, capacity: 10, fun: 10, shopIncome: 0 },
  viking: { id: "viking", name: "바이킹", emoji: "🏴‍☠️", category: "ride", cost: 2000, maintenance: 35, capacity: 15, fun: 15, shopIncome: 0 },
  ferris: { id: "ferris", name: "대관람차", emoji: "🎡", category: "ride", cost: 2600, maintenance: 40, capacity: 18, fun: 14, shopIncome: 0, lockedByResearch: true },
  bumper: { id: "bumper", name: "범퍼카", emoji: "🚗", category: "ride", cost: 1800, maintenance: 30, capacity: 14, fun: 13, shopIncome: 0, lockedByResearch: true },
  waterslide: { id: "waterslide", name: "워터슬라이드", emoji: "🛝", category: "ride", cost: 3400, maintenance: 55, capacity: 22, fun: 20, shopIncome: 0, lockedByResearch: true },
  vipGarden: { id: "vipGarden", name: "VIP 정원", emoji: "🌸", category: "utility", cost: 1200, maintenance: 12, capacity: 0, fun: 0, shopIncome: 0, lockedByMission: true },
  burger: { id: "burger", name: "햄버거 가게", emoji: "🍔", category: "shop", cost: 500, maintenance: 10, capacity: 0, fun: 0, shopIncome: 30 },
  drink: { id: "drink", name: "음료수 가게", emoji: "🥤", category: "shop", cost: 400, maintenance: 8, capacity: 0, fun: 0, shopIncome: 25 },
  restroom: { id: "restroom", name: "화장실", emoji: "🚻", category: "utility", cost: 300, maintenance: 15, capacity: 0, fun: 0, shopIncome: 0, satisfactionBonus: 8 },
  path: { id: "path", name: "길", emoji: "🟫", category: "path", cost: 10, maintenance: 0, capacity: 0, fun: 0, shopIncome: 0 },
};

const CATEGORIES = [
  { id: "ride", label: "놀이기구", icon: "🎡" },
  { id: "shop", label: "매점", icon: "🏪" },
  { id: "utility", label: "편의시설", icon: "🧰" },
  { id: "path", label: "길", icon: "🛣️" },
];

const MISSIONS = [
  { id: "visitors50", text: "방문객 50명 달성", done: (s) => s.maxVisitors >= 50, rewardMoney: 3000 },
  { id: "money50k", text: "자금 50,000원 모으기", done: (s) => s.money >= 50000, rewardMoney: 5000, rewardUnlock: "vipGarden" },
  { id: "rating80", text: "공원 평점 80 달성", done: (s) => s.rating >= 80, rewardMoney: 4000 },
];

const initialTiles = () => {
  const grid = Array.from({ length: MAP_SIZE }, () => Array.from({ length: MAP_SIZE }, () => ({ type: "grass", facilityId: null })));
  const mid = Math.floor(MAP_SIZE / 2);
  for (let y = mid - 2; y <= mid + 2; y++) grid[mid][y] = { type: "path", facilityId: null };
  return grid;
};

const keyOf = (x, y) => `${x},${y}`;
const clamp = (v, min, max) => Math.max(min, Math.min(max, v));
const isoToScreen = (x, y) => ({ x: (x - y) * (TILE_W / 2), y: (x + y) * (TILE_H / 2) });

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
  const [maxVisitors, setMaxVisitors] = useState(0);
  const [rating, setRating] = useState(50);
  const [running, setRunning] = useState(true);
  const [speed, setSpeed] = useState(1);
  const [gameMinutes, setGameMinutes] = useState(8 * 60);

  const [activeCategory, setActiveCategory] = useState("ride");
  const [selectedBuild, setSelectedBuild] = useState("rollercoaster");
  const [hoverTile, setHoverTile] = useState(null);
  const [placeValid, setPlaceValid] = useState(true);
  const [cam, setCam] = useState({ x: 420, y: 90, zoom: 1 });

  const [facilityMeta, setFacilityMeta] = useState({});
  const [selectedFacilityKey, setSelectedFacilityKey] = useState(null);
  const [unlockedRides, setUnlockedRides] = useState(["rollercoaster", "carousel", "viking"]);
  const [missionUnlocks, setMissionUnlocks] = useState([]);
  const [missionIndex, setMissionIndex] = useState(0);
  const [researching, setResearching] = useState(null);
  const [researchLeft, setResearchLeft] = useState(0);

  const [eventBanner, setEventBanner] = useState(null);
  const [activeEvent, setActiveEvent] = useState({ name: "맑음", visitorMult: 1, satDelta: 0, minutesLeft: 0 });
  const [toast, setToast] = useState(null);
  const [panel, setPanel] = useState("park");

  const [incomeHistory, setIncomeHistory] = useState([]);
  const [expenseHistory, setExpenseHistory] = useState([]);
  const [satHistory, setSatHistory] = useState([]);
  const [entryFee, setEntryFee] = useState(100);

  const viewportRef = useRef(null);
  const gestureRef = useRef({ mode: null, startX: 0, startY: 0, startCamX: 0, startCamY: 0, startDist: 0, startZoom: 1 });
  const visitorIdRef = useRef(1);
  const audioCtxRef = useRef(null);

  const playSfx = (type) => {
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) return;
    if (!audioCtxRef.current) audioCtxRef.current = new AudioCtx();
    const ctx = audioCtxRef.current;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    const now = ctx.currentTime;
    if (type === "build") {
      osc.frequency.setValueAtTime(880, now);
      osc.frequency.exponentialRampToValueAtTime(1200, now + 0.08);
      gain.gain.setValueAtTime(0.14, now);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.11);
    } else if (type === "income") {
      osc.frequency.setValueAtTime(660, now);
      osc.frequency.exponentialRampToValueAtTime(990, now + 0.08);
      gain.gain.setValueAtTime(0.12, now);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.12);
    } else {
      osc.frequency.setValueAtTime(220, now);
      gain.gain.setValueAtTime(0.11, now);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.18);
    }
    osc.start(now);
    osc.stop(now + 0.2);
  };

  const builtFacilities = useMemo(() => {
    const list = [];
    for (let x = 0; x < MAP_SIZE; x++) {
      for (let y = 0; y < MAP_SIZE; y++) {
        const t = tiles[x][y];
        if (t.type === "facility" && t.facilityId) {
          const b = BUILDINGS[t.facilityId];
          if (b) list.push({ ...b, x, y, key: keyOf(x, y), meta: facilityMeta[keyOf(x, y)] || { level: 1, users: 0, revenue: 0, broken: false } });
        }
      }
    }
    return list;
  }, [tiles, facilityMeta]);

  const pathSet = useMemo(() => {
    const s = new Set();
    for (let x = 0; x < MAP_SIZE; x++) for (let y = 0; y < MAP_SIZE; y++) if (tiles[x][y].type === "path") s.add(keyOf(x, y));
    return s;
  }, [tiles]);

  const parkStats = useMemo(() => {
    const diversity = new Set(builtFacilities.map((f) => f.id)).size;
    const brokenCount = builtFacilities.filter((f) => f.meta.broken).length;
    const cleanliness = clamp(100 - brokenCount * 12 - Math.max(0, visitors.length - 120) * 0.15, 10, 100);
    const avgSat = visitors.length ? visitors.reduce((s, v) => s + v.satisfaction, 0) / visitors.length : 50;
    return { diversity, cleanliness, avgSat };
  }, [builtFacilities, visitors]);

  const stars = useMemo(() => {
    const score = parkStats.diversity * 8 + parkStats.cleanliness * 0.3 + parkStats.avgSat * 0.5;
    return clamp(Math.round(score / 22), 1, 5);
  }, [parkStats]);

  const parkAttractiveness = useMemo(() => {
    const rideFun = builtFacilities.filter((f) => f.category === "ride").reduce((a, f) => a + f.fun + (f.meta.level - 1) * 4, 0);
    const amenity = builtFacilities.filter((f) => f.id === "restroom" || f.id === "vipGarden").reduce((a, f) => a + (f.satisfactionBonus || 6), 0);
    return rideFun + amenity + stars * 4 + Math.min(visitors.length, 100) * 0.25;
  }, [builtFacilities, visitors.length, stars]);

  const avgSatisfaction = useMemo(() => {
    if (!visitors.length) return 50;
    return visitors.reduce((s, v) => s + v.satisfaction, 0) / visitors.length;
  }, [visitors]);

  const currentMission = MISSIONS[missionIndex] || null;

  useEffect(() => {
    const value = clamp(Math.round(0.45 * avgSatisfaction + 0.35 * Math.min(100, parkAttractiveness) + stars * 4), 0, 100);
    setRating(value);
  }, [avgSatisfaction, parkAttractiveness, stars]);

  useEffect(() => {
    if (!currentMission) return;
    const done = currentMission.done({ maxVisitors, money, rating });
    if (!done) return;
    setMoney((m) => m + (currentMission.rewardMoney || 0));
    if (currentMission.rewardUnlock) setMissionUnlocks((prev) => [...new Set([...prev, currentMission.rewardUnlock])]);
    setToast(`미션 완료! +₩${(currentMission.rewardMoney || 0).toLocaleString()}`);
    setMissionIndex((i) => i + 1);
  }, [currentMission, maxVisitors, money, rating]);

  const filteredBuildOptions = useMemo(() => {
    const all = Object.values(BUILDINGS).filter((b) => b.category === activeCategory);
    if (activeCategory === "ride") return all.filter((b) => !b.lockedByResearch || unlockedRides.includes(b.id));
    if (activeCategory === "utility") return all.filter((b) => !b.lockedByMission || missionUnlocks.includes(b.id));
    return all;
  }, [activeCategory, unlockedRides, missionUnlocks]);

  useEffect(() => {
    if (!filteredBuildOptions.find((o) => o.id === selectedBuild)) setSelectedBuild(filteredBuildOptions[0]?.id || "path");
  }, [filteredBuildOptions, selectedBuild]);

  useEffect(() => {
    if (!running) return;
    const interval = setInterval(() => tickOneMinute(), 1000 / speed);
    return () => clearInterval(interval);
  }, [running, speed, tiles, facilityMeta, visitors, parkAttractiveness, activeEvent, stars, entryFee]);

  useEffect(() => {
    if (!toast) return;
    const t = setTimeout(() => setToast(null), 2600);
    return () => clearTimeout(t);
  }, [toast]);

  const isInside = (x, y) => x >= 0 && y >= 0 && x < MAP_SIZE && y < MAP_SIZE;
  const hasAdjacentPath = (x, y) => [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => {
    const nx = x + dx; const ny = y + dy;
    return isInside(nx, ny) && tiles[nx][ny].type === "path";
  });

  const canPlaceAt = (x, y, buildId) => {
    if (!isInside(x, y)) return false;
    const tile = tiles[x][y];
    const b = BUILDINGS[buildId];
    if (!b || money < b.cost) return false;
    if (b.id === "path") return tile.type === "grass";
    return tile.type === "grass" && hasAdjacentPath(x, y);
  };

  const pushHistory = (income, expense, sat) => {
    setIncomeHistory((arr) => [...arr.slice(-9), income]);
    setExpenseHistory((arr) => [...arr.slice(-9), expense]);
    setSatHistory((arr) => [...arr.slice(-9), Math.round(sat)]);
  };

  const triggerRandomEvent = () => {
    const roll = Math.random();
    if (roll < 0.33) {
      setActiveEvent({ name: "맑은 날씨 ☀️", visitorMult: 1.2, satDelta: 0.4, minutesLeft: 5 });
      setEventBanner("☀️ 날씨 버프! 방문객 증가");
    } else if (roll < 0.66) {
      setActiveEvent({ name: "축제 개최 🎉", visitorMult: 1.35, satDelta: 1.2, minutesLeft: 4 });
      setEventBanner("🎉 축제 보너스! 만족도 상승");
    } else {
      setActiveEvent({ name: "안전 점검 🚨", visitorMult: 0.7, satDelta: -1, minutesLeft: 4 });
      setEventBanner("🚨 사고 이슈! 방문객 감소");
    }
  };

  const tickOneMinute = () => {
    setGameMinutes((m) => (m + 1) % (24 * 60));

    if (researching) {
      setResearchLeft((left) => {
        const next = left - 1;
        if (next <= 0) {
          setUnlockedRides((prev) => [...new Set([...prev, researching])]);
          setToast(`연구 완료: ${BUILDINGS[researching].name} 해금!`);
          setResearching(null);
          return 0;
        }
        return next;
      });
    }

    if (activeEvent.minutesLeft > 0) {
      setActiveEvent((ev) => ({ ...ev, minutesLeft: ev.minutesLeft - 1 }));
      if (activeEvent.minutesLeft === 1) setEventBanner("이벤트 종료");
    } else if (Math.random() < 0.12) {
      triggerRandomEvent();
    }

    if (Math.random() < 0.08 && builtFacilities.length) {
      const target = builtFacilities[Math.floor(Math.random() * builtFacilities.length)];
      const fKey = target.key;
      if (!facilityMeta[fKey]?.broken) {
        setFacilityMeta((prev) => ({ ...prev, [fKey]: { ...(prev[fKey] || { level: 1, users: 0, revenue: 0 }), broken: true } }));
        setEventBanner(`${target.emoji} ${target.name} 고장! 수리가 필요합니다.`);
        playSfx("error");
      }
    }

    const maintenance = builtFacilities.reduce((sum, f) => {
      const lvl = f.meta.level || 1;
      return sum + Math.round((f.maintenance || 0) * (1 + (lvl - 1) * 0.2));
    }, 0);

    const passiveShopIncome = builtFacilities.reduce((sum, f) => {
      const lvl = f.meta.level || 1;
      if (f.meta.broken) return sum;
      return sum + Math.round((f.shopIncome || 0) * (1 + (lvl - 1) * 0.25));
    }, 0);

    const spawnChance = clamp((0.06 + parkAttractiveness / 280) * activeEvent.visitorMult * (1 - entryFee / 2000), 0.03, 0.45);

    setVisitors((prev) => {
      let next = [...prev];
      if (Math.random() < spawnChance && pathSet.size > 0 && next.length < 260) {
        const [ex, ey] = [...pathSet][Math.floor(Math.random() * pathSet.size)].split(",").map(Number);
        next.push({ id: visitorIdRef.current++, x: ex, y: ey, satisfaction: clamp(55 + Math.random() * 20, 0, 100), mood: "🙂" });
      }

      const usageCount = {};
      const revenueDeltaByFacility = {};

      next = next
        .map((v) => {
          const dirs = [[1, 0], [-1, 0], [0, 1], [0, -1]];
          const candidates = dirs.map(([dx, dy]) => ({ x: v.x + dx, y: v.y + dy })).filter((p) => p.x >= 0 && p.x < MAP_SIZE && p.y >= 0 && p.y < MAP_SIZE && pathSet.has(keyOf(p.x, p.y)));
          let nx = v.x; let ny = v.y;
          if (candidates.length) {
            const pick = candidates[Math.floor(Math.random() * candidates.length)];
            nx = pick.x; ny = pick.y;
          }

          let satDelta = -0.4 + activeEvent.satDelta - entryFee / 1200;
          for (const [dx, dy] of dirs) {
            const tx = nx + dx; const ty = ny + dy;
            if (!isInside(tx, ty)) continue;
            const t = tiles[tx][ty];
            if (t.type !== "facility" || !t.facilityId) continue;
            const b = BUILDINGS[t.facilityId];
            const fk = keyOf(tx, ty);
            const meta = facilityMeta[fk] || { level: 1, broken: false };
            if (meta.broken) continue;
            const lvl = meta.level || 1;

            if (b.category === "ride" && Math.random() < 0.17) {
              satDelta += 4 + b.fun * 0.22 + (lvl - 1) * 1.4;
              usageCount[fk] = (usageCount[fk] || 0) + 1;
            } else if (b.category === "shop" && Math.random() < 0.12) {
              satDelta += 2.2;
              usageCount[fk] = (usageCount[fk] || 0) + 1;
              revenueDeltaByFacility[fk] = (revenueDeltaByFacility[fk] || 0) + b.shopIncome;
            } else if ((b.id === "restroom" || b.id === "vipGarden") && Math.random() < 0.08) {
              satDelta += 3;
              usageCount[fk] = (usageCount[fk] || 0) + 1;
            }
          }

          return { ...v, x: nx, y: ny, satisfaction: clamp(v.satisfaction + satDelta, 0, 100) };
        })
        .filter((v) => v.satisfaction > 8 || Math.random() > 0.15);

      if (next.length > maxVisitors) setMaxVisitors(next.length);

      if (Object.keys(usageCount).length || Object.keys(revenueDeltaByFacility).length) {
        setFacilityMeta((prev) => {
          const nextMeta = { ...prev };
          for (const k of Object.keys(usageCount)) {
            const p = nextMeta[k] || { level: 1, users: 0, revenue: 0, broken: false };
            nextMeta[k] = { ...p, users: (p.users || 0) + usageCount[k] };
          }
          for (const k of Object.keys(revenueDeltaByFacility)) {
            const p = nextMeta[k] || { level: 1, users: 0, revenue: 0, broken: false };
            nextMeta[k] = { ...p, revenue: (p.revenue || 0) + revenueDeltaByFacility[k] };
          }
          return nextMeta;
        });
      }

      return next;
    });

    const entranceIncome = Math.round(visitors.length * entryFee * 0.2);
    const activityIncome = Math.round(visitors.length * 1.3 + parkAttractiveness * 0.2 * activeEvent.visitorMult);
    const income = passiveShopIncome + activityIncome + entranceIncome;
    const expense = maintenance;
    setMoney((m) => m + income - expense);
    if (income > expense + 20) playSfx("income");
    pushHistory(income, expense, avgSatisfaction);
  };

  const placeBuilding = (x, y) => {
    const b = BUILDINGS[selectedBuild];
    if (!b || !canPlaceAt(x, y, selectedBuild)) return;
    setTiles((prev) => {
      const next = prev.map((r) => r.slice());
      next[x][y] = selectedBuild === "path" ? { type: "path", facilityId: null } : { type: "facility", facilityId: selectedBuild };
      return next;
    });
    if (selectedBuild !== "path") setFacilityMeta((prev) => ({ ...prev, [keyOf(x, y)]: { level: 1, users: 0, revenue: 0, broken: false } }));
    setMoney((m) => m - b.cost);
    playSfx("build");
  };

  const selectedFacility = useMemo(() => {
    if (!selectedFacilityKey) return null;
    const [x, y] = selectedFacilityKey.split(",").map(Number);
    const tile = tiles[x]?.[y];
    if (!tile || tile.type !== "facility" || !tile.facilityId) return null;
    return { x, y, key: selectedFacilityKey, building: BUILDINGS[tile.facilityId], meta: facilityMeta[selectedFacilityKey] || { level: 1, users: 0, revenue: 0, broken: false } };
  }, [selectedFacilityKey, tiles, facilityMeta]);

  const tryOpenFacilityPopup = (x, y) => {
    const tile = tiles[x]?.[y];
    if (tile?.type === "facility" && tile.facilityId) { setSelectedFacilityKey(keyOf(x, y)); return true; }
    return false;
  };

  const upgradeFacility = () => {
    if (!selectedFacility) return;
    const lvl = selectedFacility.meta.level || 1;
    const upgradeCost = Math.round(selectedFacility.building.cost * (0.5 + lvl * 0.35));
    if (money < upgradeCost) return;
    setMoney((m) => m - upgradeCost);
    setFacilityMeta((prev) => ({ ...prev, [selectedFacility.key]: { ...prev[selectedFacility.key], level: lvl + 1 } }));
    setToast(`${selectedFacility.building.name} Lv.${lvl + 1} 업그레이드 완료`);
    playSfx("build");
  };

  const repairFacility = () => {
    if (!selectedFacility?.meta?.broken) return;
    const fee = Math.round((selectedFacility.building.maintenance || 20) * 10);
    if (money < fee) return;
    setMoney((m) => m - fee);
    setFacilityMeta((prev) => ({ ...prev, [selectedFacility.key]: { ...prev[selectedFacility.key], broken: false } }));
    setToast(`${selectedFacility.building.name} 수리 완료`);
  };

  const demolishFacility = () => {
    if (!selectedFacility) return;
    const refund = Math.round(selectedFacility.building.cost * 0.5);
    const { x, y, key } = selectedFacility;
    setTiles((prev) => {
      const next = prev.map((r) => r.slice());
      next[x][y] = { type: "grass", facilityId: null };
      return next;
    });
    setFacilityMeta((prev) => { const n = { ...prev }; delete n[key]; return n; });
    setMoney((m) => m + refund);
    setSelectedFacilityKey(null);
    setToast(`철거 완료 (+₩${refund.toLocaleString()})`);
  };

  const startResearch = (rideId) => {
    const costs = { ferris: 1200, bumper: 1000, waterslide: 1500 };
    const times = { ferris: 4, bumper: 3, waterslide: 5 };
    if (researching || unlockedRides.includes(rideId) || money < (costs[rideId] || 1000)) return;
    setMoney((m) => m - costs[rideId]);
    setResearching(rideId);
    setResearchLeft(times[rideId]);
    setToast(`${BUILDINGS[rideId].name} 연구 시작`);
  };

  const handlePointerDown = (e) => {
    if (!viewportRef.current) return;
    const rect = viewportRef.current.getBoundingClientRect();
    if (e.touches && e.touches.length === 2) {
      const [t1, t2] = e.touches;
      gestureRef.current = { mode: "pinch", startDist: Math.hypot(t2.clientX - t1.clientX, t2.clientY - t1.clientY), startZoom: cam.zoom, startCamX: cam.x, startCamY: cam.y };
      return;
    }
    const p = e.touches ? e.touches[0] : e;
    gestureRef.current = { mode: "drag", startX: p.clientX, startY: p.clientY, startCamX: cam.x, startCamY: cam.y };
    const tile = screenToIso(p.clientX - rect.left, p.clientY - rect.top, cam.x, cam.y, cam.zoom);
    if (isInside(tile.x, tile.y)) { setHoverTile(tile); setPlaceValid(canPlaceAt(tile.x, tile.y, selectedBuild)); }
  };

  const handlePointerMove = (e) => {
    if (!viewportRef.current) return;
    const rect = viewportRef.current.getBoundingClientRect();
    if (e.touches && e.touches.length === 2 && gestureRef.current.mode === "pinch") {
      e.preventDefault();
      const [t1, t2] = e.touches;
      const newZoom = clamp(gestureRef.current.startZoom * (Math.hypot(t2.clientX - t1.clientX, t2.clientY - t1.clientY) / (gestureRef.current.startDist || 1)), MIN_ZOOM, MAX_ZOOM);
      setCam((prev) => ({ ...prev, zoom: newZoom }));
      return;
    }
    const p = e.touches ? e.touches[0] : e;
    if (gestureRef.current.mode === "drag") setCam((prev) => ({ ...prev, x: gestureRef.current.startCamX + (p.clientX - gestureRef.current.startX), y: gestureRef.current.startCamY + (p.clientY - gestureRef.current.startY) }));
    const tile = screenToIso(p.clientX - rect.left, p.clientY - rect.top, cam.x, cam.y, cam.zoom);
    if (isInside(tile.x, tile.y)) { setHoverTile(tile); setPlaceValid(canPlaceAt(tile.x, tile.y, selectedBuild)); } else { setHoverTile(null); setPlaceValid(false); }
  };

  const handlePointerUp = (e) => {
    if (!viewportRef.current) return;
    const rect = viewportRef.current.getBoundingClientRect();
    const p = e.changedTouches ? e.changedTouches[0] : e;
    const tile = screenToIso(p.clientX - rect.left, p.clientY - rect.top, cam.x, cam.y, cam.zoom);
    if (isInside(tile.x, tile.y)) {
      const moved = Math.hypot(p.clientX - (gestureRef.current.startX || p.clientX), p.clientY - (gestureRef.current.startY || p.clientY)) > 8;
      if (!moved && gestureRef.current.mode !== "pinch") {
        if (!tryOpenFacilityPopup(tile.x, tile.y)) placeBuilding(tile.x, tile.y);
      }
    }
    gestureRef.current.mode = null;
  };

  const timeLabel = `${String(Math.floor(gameMinutes / 60)).padStart(2, "0")}:${String(gameMinutes % 60).padStart(2, "0")}`;
  const barMax = useMemo(() => Math.max(1, ...incomeHistory, ...expenseHistory), [incomeHistory, expenseHistory]);

  const popularity = useMemo(() => [...builtFacilities].sort((a, b) => (b.meta.users || 0) - (a.meta.users || 0)).slice(0, 5).map((f) => ({ name: `${f.emoji} ${f.name}`, users: f.meta.users || 0 })), [builtFacilities]);

  return (
    <div className="h-screen w-full bg-gradient-to-b from-amber-50 to-lime-100 text-slate-800 flex flex-col overflow-hidden select-none">
      <header className="px-3 pt-3 pb-2 z-20">
        <div className="rounded-2xl bg-white/90 backdrop-blur shadow-md p-2.5">
          <div className="grid grid-cols-3 gap-2 text-center text-sm">
            <div className="rounded-xl bg-emerald-50 p-2 min-h-[44px]"><div className="text-[11px] text-emerald-700">자금</div><div className="font-bold text-emerald-800">₩ {money.toLocaleString()}</div></div>
            <div className="rounded-xl bg-sky-50 p-2 min-h-[44px]"><div className="text-[11px] text-sky-700">방문객</div><div className="font-bold text-sky-800">{visitors.length}명</div></div>
            <div className="rounded-xl bg-amber-50 p-2 min-h-[44px]"><div className="text-[11px] text-amber-700">평점/등급</div><div className="font-bold text-amber-800">{rating} · {'⭐'.repeat(stars)}</div></div>
          </div>
          <div className="flex items-center justify-between mt-2">
            <div className="text-xs font-medium text-slate-600">🕒 {timeLabel} · {activeEvent.name}</div>
            <div className="flex gap-2">
              <button className={`min-w-[44px] min-h-[44px] px-3 rounded-xl text-sm font-semibold ${running ? "bg-slate-100" : "bg-slate-800 text-white"}`} onClick={() => setRunning((v) => !v)}>{running ? "⏸" : "▶"}</button>
              <button className={`min-w-[44px] min-h-[44px] px-3 rounded-xl text-sm font-semibold ${speed === 1 ? "bg-violet-100 text-violet-800" : "bg-violet-600 text-white"}`} onClick={() => setSpeed((s) => (s === 1 ? 2 : 1))}>{speed}x</button>
              <button className="min-w-[44px] min-h-[44px] px-3 rounded-xl text-sm font-semibold bg-slate-200" onClick={() => setPanel((p) => (p === "park" ? "stats" : "park"))}>{panel === "park" ? "📊" : "🏞️"}</button>
            </div>
          </div>
          <div className="mt-2 flex items-center gap-2 text-xs">
            <span>입장료</span>
            <button className="min-w-[44px] min-h-[32px] bg-slate-100 rounded-lg" onClick={() => setEntryFee((v) => clamp(v - 10, 50, 300))}>-</button>
            <span className="font-semibold">₩{entryFee}</span>
            <button className="min-w-[44px] min-h-[32px] bg-slate-100 rounded-lg" onClick={() => setEntryFee((v) => clamp(v + 10, 50, 300))}>+</button>
            <span className="text-slate-500">(등급 {stars}⭐ 권장)</span>
          </div>
        </div>
        {eventBanner && <div className="mt-2 rounded-xl bg-indigo-600 text-white px-3 py-2 text-sm shadow">{eventBanner}</div>}
      </header>

      <div className="px-3 pb-1">
        <div className="rounded-xl bg-white/90 px-3 py-2 text-sm shadow">
          🎯 현재 미션: {currentMission ? currentMission.text : "모든 미션 완료"}
        </div>
      </div>

      {panel === "park" ? (
        <main className="flex-1 px-2 pb-2 relative">
          <div ref={viewportRef} className="h-full w-full rounded-2xl bg-lime-200/80 shadow-inner border border-white/70 overflow-hidden touch-none relative" onMouseDown={handlePointerDown} onMouseMove={handlePointerMove} onMouseUp={handlePointerUp} onTouchStart={handlePointerDown} onTouchMove={handlePointerMove} onTouchEnd={handlePointerUp}>
            <div className="absolute left-0 top-0" style={{ transform: `translate(${cam.x}px, ${cam.y}px) scale(${cam.zoom})`, transformOrigin: "0 0", willChange: "transform" }}>
              {Array.from({ length: MAP_SIZE }).map((_, x) => Array.from({ length: MAP_SIZE }).map((__, y) => {
                const tile = tiles[x][y]; const pos = isoToScreen(x, y);
                const bg = tile.type === "grass" ? "bg-lime-400" : tile.type === "path" ? "bg-amber-200" : "bg-lime-300";
                return <div key={`${x}-${y}`} className={`absolute ${bg} border border-white/45`} style={{ width: TILE_W, height: TILE_H, left: pos.x - TILE_W / 2, top: pos.y - TILE_H / 2, transform: "skewY(-26.565deg) scaleY(0.5)", borderRadius: 2 }} />;
              }))}
              {builtFacilities.map((f) => { const pos = isoToScreen(f.x, f.y); return <div key={`f-${f.key}`} className="absolute text-2xl" style={{ left: pos.x - 12, top: pos.y - 32 }}>{f.emoji}{f.meta.broken ? "❌" : ""}</div>; })}
              {visitors.map((v) => { const pos = isoToScreen(v.x, v.y); return <div key={v.id} className="absolute transition-all duration-500 ease-linear" style={{ left: pos.x - 6, top: pos.y - 12 }}><div className="w-3 h-3 rounded-full bg-sky-600 border border-white shadow" /></div>; })}
              {hoverTile && isInside(hoverTile.x, hoverTile.y) && (() => { const pos = isoToScreen(hoverTile.x, hoverTile.y); return <div className={`absolute border-2 ${placeValid ? "border-emerald-500/80" : "border-red-500/90"}`} style={{ width: TILE_W, height: TILE_H, left: pos.x - TILE_W / 2, top: pos.y - TILE_H / 2, transform: "skewY(-26.565deg) scaleY(0.5)", borderRadius: 2 }} />; })()}
            </div>
            <div className="absolute left-2 top-2 text-[11px] bg-white/80 rounded-lg px-2 py-1">드래그: 이동 · 핀치: 줌 · 시설 탭: 관리</div>
          </div>
        </main>
      ) : (
        <main className="flex-1 px-3 pb-2 overflow-y-auto">
          <div className="rounded-2xl bg-white p-3 shadow mb-3"><div className="font-semibold mb-2">최근 10분 수입/지출</div><div className="flex items-end gap-1 h-24">{Array.from({ length: Math.max(incomeHistory.length, expenseHistory.length) }).map((_, i) => { const inc = incomeHistory[i] || 0; const exp = expenseHistory[i] || 0; return <div key={i} className="flex-1 flex items-end gap-[2px]"><div className="w-1/2 bg-emerald-400 rounded-t" style={{ height: `${(inc / barMax) * 100}%` }} /><div className="w-1/2 bg-rose-400 rounded-t" style={{ height: `${(exp / barMax) * 100}%` }} /></div>; })}</div></div>
          <div className="rounded-2xl bg-white p-3 shadow mb-3"><div className="font-semibold mb-2">인기 시설 순위</div>{popularity.length ? popularity.map((p, idx) => <div key={p.name} className="flex justify-between text-sm py-1"><span>{idx + 1}. {p.name}</span><span>{p.users}회</span></div>) : <div className="text-sm text-slate-500">아직 데이터가 없어요.</div>}</div>
          <div className="rounded-2xl bg-white p-3 shadow"><div className="font-semibold mb-2">방문객 만족도 추이</div><div className="flex items-end gap-1 h-20">{satHistory.map((s, i) => <div key={i} className="flex-1 bg-blue-400 rounded-t" style={{ height: `${clamp(s, 5, 100)}%` }} />)}</div></div>
        </main>
      )}

      <footer className="px-2 pb-2 z-20">
        <div className="rounded-2xl bg-white/95 shadow-lg p-2 mb-2">
          <div className="text-xs font-semibold mb-2">연구 시스템</div>
          <div className="flex gap-2 overflow-x-auto">
            {["ferris", "bumper", "waterslide"].map((id) => { const b = BUILDINGS[id]; const unlocked = unlockedRides.includes(id); return <button key={id} onClick={() => startResearch(id)} className="min-w-[120px] min-h-[44px] rounded-xl px-2 py-1 text-left border border-slate-200 bg-slate-50"><div className="text-sm">{b.emoji} {b.name}</div><div className="text-[11px] text-slate-500">{unlocked ? "해금 완료" : researching === id ? `연구중 ${researchLeft}분` : "탭해서 연구"}</div></button>; })}
          </div>
        </div>

        <div className="rounded-2xl bg-white/95 shadow-lg p-2">
          <div className="grid grid-cols-4 gap-2 mb-2">{CATEGORIES.map((cat) => <button key={cat.id} onClick={() => setActiveCategory(cat.id)} className={`min-h-[44px] rounded-xl text-xs font-semibold flex items-center justify-center gap-1 ${activeCategory === cat.id ? "bg-slate-800 text-white" : "bg-slate-100 text-slate-700"}`}><span>{cat.icon}</span><span>{cat.label}</span></button>)}</div>
          <div className="flex gap-2 overflow-x-auto pb-1">{filteredBuildOptions.map((b) => <button key={b.id} onClick={() => setSelectedBuild(b.id)} className={`min-w-[124px] min-h-[64px] rounded-xl px-2 py-1 text-left border ${selectedBuild === b.id ? "border-violet-500 bg-violet-50" : "border-slate-200 bg-white"}`}><div className="flex items-center gap-1.5"><span className="text-xl">{b.emoji}</span><span className="font-semibold text-sm">{b.name}</span></div><div className="text-[11px] text-slate-600">건설 ₩{b.cost.toLocaleString()}</div></button>)}</div>
        </div>
      </footer>

      {selectedFacility && <div className="absolute inset-0 bg-black/35 flex items-center justify-center z-30 p-4"><div className="w-full max-w-sm bg-white rounded-2xl p-4 shadow-xl"><div className="flex justify-between items-center mb-2"><div className="font-bold">{selectedFacility.building.emoji} {selectedFacility.building.name}</div><button className="min-w-[44px] min-h-[44px]" onClick={() => setSelectedFacilityKey(null)}>✕</button></div><div className="text-sm space-y-1 mb-3"><div>상태: {selectedFacility.meta.broken ? "고장" : "정상"}</div><div>누적 이용객: {selectedFacility.meta.users || 0}명</div><div>누적 수익: ₩{(selectedFacility.meta.revenue || 0).toLocaleString()}</div><div>레벨: Lv.{selectedFacility.meta.level || 1}</div></div><div className="grid grid-cols-3 gap-2"><button className="min-h-[44px] rounded-xl bg-indigo-100" onClick={upgradeFacility}>업그레이드</button><button className="min-h-[44px] rounded-xl bg-amber-100" onClick={repairFacility}>수리</button><button className="min-h-[44px] rounded-xl bg-rose-100" onClick={demolishFacility}>철거</button></div></div></div>}
      {toast && <div className="absolute top-24 left-1/2 -translate-x-1/2 bg-slate-900 text-white text-sm px-3 py-2 rounded-xl shadow-lg z-40">{toast}</div>}
    </div>
  );
}
