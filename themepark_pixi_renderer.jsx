import React, { useEffect, useMemo, useRef, useState } from "react";
import { Application, Container, Graphics, Stage, Text } from "@pixi/react";
import { BUILDINGS, MAP_SIZE, createInitialGameState, isoToScreen, placeBuilding, screenToIso, tickOneMinute } from "./themepark_game_core";

const TILE_W = 64;
const TILE_H = 32;

function drawIsoTile(g, color = 0x79b85f) {
  g.clear();
  g.lineStyle(1, 0x2f3e2c, 0.6);
  g.beginFill(color);
  g.moveTo(0, TILE_H / 2);
  g.lineTo(TILE_W / 2, 0);
  g.lineTo(TILE_W, TILE_H / 2);
  g.lineTo(TILE_W / 2, TILE_H);
  g.closePath();
  g.endFill();
}

function Tile({ x, y, tileType, cam }) {
  const pos = isoToScreen(x, y, TILE_W, TILE_H);
  const color = tileType === "grass" ? 0x7dbf62 : tileType === "path" ? 0xd8bf8b : 0x98cb82;
  return (
    <Graphics
      x={cam.x + pos.x - TILE_W / 2}
      y={cam.y + pos.y - TILE_H / 2}
      draw={(g) => drawIsoTile(g, color)}
    />
  );
}

function FacilitySprite({ facility, cam }) {
  const pos = isoToScreen(facility.x, facility.y, TILE_W, TILE_H);
  const tint =
    facility.category === "ride" ? 0xd64040 : facility.category === "shop" ? 0xdb8c39 : 0x78b6d9;
  return (
    <Container x={cam.x + pos.x - 14} y={cam.y + pos.y - 30}>
      <Graphics
        draw={(g) => {
          g.clear();
          g.lineStyle(2, 0x24301f, 1);
          g.beginFill(tint);
          g.drawRect(0, 0, 28, 28);
          g.endFill();
        }}
      />
      <Text text={facility.meta?.broken ? "❌" : ""} style={{ fontSize: 10 }} x={2} y={2} />
    </Container>
  );
}

function GuestSprite({ guest, cam }) {
  const pos = isoToScreen(guest.x, guest.y, TILE_W, TILE_H);
  return (
    <Graphics
      x={cam.x + pos.x - 4}
      y={cam.y + pos.y - 10}
      draw={(g) => {
        g.clear();
        g.lineStyle(1, 0x1f2a1c, 1);
        g.beginFill(0x4aa3ff);
        g.drawRect(0, 0, 8, 5);
        g.endFill();
        g.beginFill(0xf4d2a0);
        g.drawRect(0, 5, 8, 5);
        g.endFill();
      }}
    />
  );
}

export default function ThemeParkPixiRenderer() {
  const [state, setState] = useState(createInitialGameState);
  const [running, setRunning] = useState(true);
  const [speed, setSpeed] = useState(1);
  const [selectedBuild, setSelectedBuild] = useState("rollercoaster");
  const [cam, setCam] = useState({ x: 420, y: 90, zoom: 1 });

  const dragRef = useRef({ dragging: false, sx: 0, sy: 0, cx: 0, cy: 0 });

  useEffect(() => {
    if (!running) return;
    const id = setInterval(() => setState((prev) => tickOneMinute(prev)), 1000 / speed);
    return () => clearInterval(id);
  }, [running, speed]);

  const facilities = useMemo(() => {
    const out = [];
    for (let x = 0; x < MAP_SIZE; x++) {
      for (let y = 0; y < MAP_SIZE; y++) {
        const t = state.tiles[x][y];
        if (t.type === "facility" && t.facilityId) {
          out.push({
            ...BUILDINGS[t.facilityId],
            x,
            y,
            meta: state.facilityMeta[`${x},${y}`] || { level: 1, broken: false },
          });
        }
      }
    }
    return out;
  }, [state.tiles, state.facilityMeta]);

  const onPointerDown = (e) => {
    dragRef.current = { dragging: true, sx: e.clientX, sy: e.clientY, cx: cam.x, cy: cam.y };
  };

  const onPointerMove = (e) => {
    if (!dragRef.current.dragging) return;
    const dx = e.clientX - dragRef.current.sx;
    const dy = e.clientY - dragRef.current.sy;
    setCam((prev) => ({ ...prev, x: dragRef.current.cx + dx, y: dragRef.current.cy + dy }));
  };

  const onPointerUp = (e) => {
    if (!dragRef.current.dragging) return;
    const moved = Math.hypot(e.clientX - dragRef.current.sx, e.clientY - dragRef.current.sy) > 8;
    dragRef.current.dragging = false;
    if (moved) return;

    const rect = e.currentTarget.getBoundingClientRect();
    const p = screenToIso(e.clientX - rect.left, e.clientY - rect.top, cam.x, cam.y, cam.zoom, TILE_W, TILE_H);
    setState((prev) => placeBuilding(prev, p.x, p.y, selectedBuild));
  };

  return (
    <div className="h-screen w-full bg-[#7bb26a] text-slate-900 flex flex-col font-mono">
      <div className="p-2 bg-[#d7e9c8] border-b-2 border-[#2f3e2c] flex items-center justify-between">
        <div className="text-sm font-bold">₩ {state.money.toLocaleString()} · 방문객 {state.visitors.length} · 평점 {state.rating}</div>
        <div className="flex gap-2">
          <button className="px-2 py-1 border-2 border-[#2f3e2c] bg-white" onClick={() => setRunning((v) => !v)}>{running ? "⏸" : "▶"}</button>
          <button className="px-2 py-1 border-2 border-[#2f3e2c] bg-white" onClick={() => setSpeed((s) => (s === 1 ? 2 : 1))}>{speed}x</button>
        </div>
      </div>

      <div className="flex-1" onMouseDown={onPointerDown} onMouseMove={onPointerMove} onMouseUp={onPointerUp}>
        <Stage width={window.innerWidth} height={window.innerHeight - 130} options={{ backgroundAlpha: 0, antialias: false }}>
          <Container scale={cam.zoom}>
            {Array.from({ length: MAP_SIZE }).map((_, x) =>
              Array.from({ length: MAP_SIZE }).map((__, y) => (
                <Tile key={`${x}-${y}`} x={x} y={y} tileType={state.tiles[x][y].type} cam={cam} />
              ))
            )}
            {facilities.map((f) => (
              <FacilitySprite key={`f-${f.x}-${f.y}`} facility={f} cam={cam} />
            ))}
            {state.visitors.map((v) => (
              <GuestSprite key={v.id} guest={v} cam={cam} />
            ))}
          </Container>
        </Stage>
      </div>

      <div className="p-2 bg-[#dfeccd] border-t-2 border-[#2f3e2c] flex gap-2 overflow-x-auto">
        {Object.values(BUILDINGS)
          .filter((b) => ["ride", "shop", "utility", "path"].includes(b.category))
          .map((b) => (
            <button
              key={b.id}
              onClick={() => setSelectedBuild(b.id)}
              className={`px-2 py-1 border-2 border-[#2f3e2c] ${selectedBuild === b.id ? "bg-[#ffe9a8]" : "bg-white"}`}
            >
              {b.name}
            </button>
          ))}
      </div>
    </div>
  );
}
