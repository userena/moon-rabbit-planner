from pathlib import Path
import shutil
root = Path(__file__).resolve().parent.parent
out = root / 'web' / 'assets'
out.mkdir(parents=True, exist_ok=True)
for source in (root / 'Sources' / 'MoonRabbit' / 'Resources').glob('*.png'):
    shutil.copy2(source, out / source.name)
print('Prepared rabbit assets:', len(list(out.glob('*.png'))))
