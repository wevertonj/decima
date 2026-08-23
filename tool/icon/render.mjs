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
import pngToIco from 'png-to-ico';
import { mkdir, writeFile } from 'node:fs/promises';
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

// Ícone Windows (app_icon.ico): o Windows NÃO aplica máscara própria — os
// cantos arredondados precisam estar no próprio .ico (com transparência).
// Por isso a fonte aqui é o MASTER (squircle 22,4%), não o full-bleed, e cada
// tamanho é rasterizado direto do vetor. Entradas armazenadas como BMP pelo
// png-to-ico — máxima compatibilidade com o shell (taskbar, Menu Iniciar,
// alt-tab). Consumido pelo Runner.rc (embutido no exe) e pelo SetupIconFile
// do instalador. `flutter_launcher_icons` está com `windows.generate: false`
// para não sobrescrever este arquivo com o full-bleed quadrado de 48 px.
const ICO_SIZES = [16, 20, 24, 32, 40, 48, 64, 256];
const ICO_OUT = p('windows', 'runner', 'resources', 'app_icon.ico');
const icoPngs = await Promise.all(ICO_SIZES.map((size) =>
  sharp(p('assets/icon/decima_icon_master.svg'), { density: 300 })
    .resize(size, size).png().toBuffer()));
await writeFile(ICO_OUT, await pngToIco(icoPngs));
console.log(`${path.relative(ROOT, ICO_OUT)} (${ICO_SIZES.join('/')})`);

// Ícone Linux (tema hicolor): o `flutter_launcher_icons` NÃO tem suporte a
// Linux — quem entrega o ícone é o `.desktop` (`Icon=com.wevasoft.decima`),
// resolvido pelo tema de ícones instalado. Como no Windows, os ambientes
// Linux não aplicam máscara própria, então a fonte é o MASTER (squircle com
// transparência), não o full-bleed. O nome dos arquivos precisa bater com o
// `Icon=` do `.desktop`, que por sua vez bate com o app ID / `WM_CLASS` —
// é assim que o WM liga a janela ao ícone.
const HICOLOR_SIZES = [16, 24, 32, 48, 64, 128, 256, 512];
const HICOLOR_DIR = p('linux', 'packaging', 'icons', 'hicolor');
for (const size of HICOLOR_SIZES) {
  const out = path.join(HICOLOR_DIR, `${size}x${size}`, 'apps', 'com.wevasoft.decima.png');
  await mkdir(path.dirname(out), { recursive: true });
  await sharp(p('assets/icon/decima_icon_master.svg'), { density: 300 })
    .resize(size, size).png().toFile(out);
}
console.log(`${path.relative(ROOT, HICOLOR_DIR)}/*/apps/com.wevasoft.decima.png (${HICOLOR_SIZES.join('/')})`);

console.log('\nPNGs derivados OK. Agora rode na raiz:');
console.log('  dart run flutter_launcher_icons && dart run flutter_native_splash:create');
