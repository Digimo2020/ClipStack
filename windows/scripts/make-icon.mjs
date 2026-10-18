import fs from 'node:fs/promises';
import pngToIco from 'png-to-ico';

const source = new URL('../assets/app-icon.png', import.meta.url);
const target = new URL('../assets/clipstack.ico', import.meta.url);
const ico = await pngToIco(await fs.readFile(source));
await fs.writeFile(target, ico);
console.log('Generated Windows app icon.');
