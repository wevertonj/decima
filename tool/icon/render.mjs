// Rasteriza os SVGs versionados do ícone/splash nos PNGs derivados — fonte
// única do pipeline de export. Uso:
//
//   cd tool/icon && npm install && npm run render
//   dart run flutter_launcher_icons          # depois, na raiz do projeto
//   dart run flutter_native_splash:create
//
// Por que `sharp` (libvips): o renderer SVG interno do ImageMagick (`convert`)
// NÃO suporta gradiente SVG (rasteriza o fundo preto) — nunca usar `convert`
// nem outro renderer sem conferir gradiente + <mask> + <clipPath>. O `sharp`
// embute librsvg e cobre os três. Regra do pipeline: PNG é sempre derivado 1:1
// do SVG homônimo — nunca editar PNG diretamente.
//
// `assets/branding/logo.png` fica em 1024 nas três densidades (como o
// original): a splash (flutter_native_splash) trata o mesmo arquivo como 4x —
// reduzir o base mudaria o tamanho visual da splash.
import sharp from 'sharp';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const p = (...seg) => path.join(ROOT, ...seg);

// [fonte SVG, tamanho do PNG (quadrado), destino]
const JOBS = [
  // Master da marca (squircle transparente) — logo de runtime (`AppLogo`) e
  // imagem da splash pré-Android 12 (tratada como 4x)
  [p('assets/icon/decima_icon_master.svg'), 1024, p('assets/branding/logo.png')],
  [p('assets/icon/decima_icon_master.svg'), 1024, p('assets/branding/2.0x/logo.png')],
  [p('assets/icon/decima_icon_master.svg'), 1024, p('assets/branding/3.0x/logo.png')],
  // Camadas de build (fora do bundle)
  [p('assets/icon/decima_icon_fullbleed.svg'), 1024, p('assets/icon/decima_icon_fullbleed.png')],
  [p('assets/icon/decima_icon_background.svg'), 1024, p('assets/icon/decima_icon_background.png')],
  [p('assets/icon/decima_icon_foreground.svg'), 1024, p('assets/icon/decima_icon_foreground.png')],
  // Splash Android 12+ (medalhão centrado no círculo seguro de 2/3)
  [p('assets/icon/decima_splash_android12.svg'), 1536, p('assets/branding/logo_splash_android12.png')],
];

for (const [svg, size, out] of JOBS) {
  // density alta antes do resize evita serrilhado na rasterização do vetor
  await sharp(svg, { density: 300 }).resize(size, size).png().toFile(out);
  console.log(`${path.relative(ROOT, out)} (${size}×${size})`);
}
console.log('\nPNGs derivados OK. Agora rode na raiz:');
console.log('  dart run flutter_launcher_icons && dart run flutter_native_splash:create');
