# PixiJS 렌더러 전환 가이드

기존 로직 유지 + 렌더링만 Canvas/WebGL(PixiJS)로 교체하는 구조입니다.

## 추가된 파일
- `themepark_game_core.js`: 렌더러 독립 게임 로직
- `themepark_pixi_renderer.jsx`: React + PixiJS 렌더러

## 설치
```bash
npm i pixi.js @pixi/react
```

## 사용
```jsx
import ThemeParkPixiRenderer from "./themepark_pixi_renderer";

export default function App() {
  return <ThemeParkPixiRenderer />;
}
```

## 설계 포인트
- 게임 루프/경제/방문객 이동은 `themepark_game_core.js`에서 처리
- Pixi 컴포넌트는 타일/시설/방문객 렌더와 카메라 입력만 담당
- `themepark_pixi_renderer.jsx`는 아래 경로의 스프라이트를 바로 읽습니다.
  - `/assets/sprites/tiles/*.png`
  - `/assets/sprites/facilities/*.png`
  - `/assets/sprites/guests/*.png`
- 파일이 없으면 일부 요소는 fallback 그래픽으로 렌더됩니다.
