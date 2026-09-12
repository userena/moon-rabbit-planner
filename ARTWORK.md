# Character artwork

Generated using the built-in image_gen tool from the user's reference illustration. Asset: `Sources/MoonRabbit/Resources/rabbit.png`. Original reference is not included.

## Prompt

Use case: background-extraction / identity-preserve. Create one full body desktop pet sprite of ONLY the brown rabbit on the RIGHT of the reference. Preserve its adorable brown plush fur, enormous glossy dark eyes, pink inner upright ears, mauve headband with cream flower at right temple, cream Korean hanbok jacket and dusty rose skirt. Reconstruct the lower skirt and tiny feet to show entire character standing. Empty paws held sweetly near chest, no paper. Same exquisite illustrated soft fur and embroidered fabric. One character centered, front facing, ears and feet entirely within frame with small padding. Actual TRANSPARENT alpha background, no scene, no checkerboard, no text, no floor, no shadow backdrop, no other objects. Asset for animated macOS desktop companion. Portrait 1024x1536 if possible.

## Additional poses

Built-in image_gen edits using `rabbit.png` as reference. Common prompt:

> Edit the supplied desktop rabbit sprite. Preserve EXACT same brown plush rabbit identity, proportions, flower headband, cream and dusty rose hanbok, fur texture and visual style. Change pose/expression only: [POSE] Full body centered, same scale and framing as reference, ears and feet fully visible. Actual transparent alpha background, no background objects, no shadows behind character, no text. One single character sprite.

- `snack.png`: Eating a small carrot held with both paws near mouth, eyes happily half closed, cheeks slightly full.
- `smile.png`: Joyful smile with crescent closed eyes, paws gently beside cheeks, visibly happy and adorable.
- `dance.png`: Dancing cheerfully with both arms extended outwards and one small foot raised, skirt gently swaying, delighted expression.

For the final smile and dance assets, edits were regenerated from the original transparent `rabbit.png` with this prompt:

> Use case: identity-preserve. Transparent-background desktop pet cutout. Modify the character in the provided transparent image: [POSE]. Preserve the same adorable brown plush bunny, cream flower mauve headband, cream Korean hanbok jacket, dusty rose skirt, full-body scale and central portrait composition. Keep the empty transparent alpha background exactly as in the original input. Render the rabbit alone. Everything outside the rabbit silhouette must have zero opacity.

- Smile pose: both paws on cheeks, crescent-shaped closed eyes, big happy smile.
- Dance pose: arms stretched out in a happy dance, one foot lifted, smiling mouth open.

## Walking, blinking, stretching, and flowers

Additional built-in image_gen edits used the same transparent reference and identity-preserving prompt structure. These requested paired animation keyframes, retaining the same rabbit, hanbok, framing, and scale.

- `walkA`: Left paw forward/lifted, right paw back/down; left foot steps forward, right foot behind.
- `walkB`: Right paw forward/lifted, left paw back/down; right foot steps forward, left foot behind.
- `blink`: Both eyes close naturally with relaxed curved eyelids; mouth, arms, paws, feet, head and costume stay unchanged.
- `danceB`: Shift weight to the opposite leg, lift the other foot, lower the left arm and lift the right arm, with an opposite lean.
- `snackB`: Lower both paws and the carrot away from the mouth, rotate the carrot slightly, close the mouth into a chewing smile.
- `stretch`: Extend both arms horizontally, gently open the shoulders/chest, feet on the ground.
- `stretchB`: Raise both paws beside the ears in an overhead stretch, feet on the ground.
- `flower`: Hold one pink daisy with a green stem near the chest, smiling warmly.
- `flowerB`: Offer the daisy forward with both paws and a slight bow.

Shared final instruction:

> Preserve the exact same adorable brown plush bunny, cream flower mauve headband, cream Korean hanbok jacket, dusty rose skirt, full-body scale and central portrait composition. Keep the empty transparent alpha background exactly as in the original input. Render the rabbit alone with only the specified prop if any. Everything outside the rabbit silhouette and prop must have zero opacity. Keep entire character, paws and ears inside frame with padding.

The generated assets sometimes contained a painted checkerboard. At the user's explicit request, local Python/Pillow/NumPy processing removed neutral background pixels connected to the image boundary, with a small inward feather along the silhouette. Existing true-alpha assets were retained. Every final pose was reviewed on dark and light backgrounds; automated tests verify transparent corners and an opaque character center. The app itself does not require Python or any image-processing dependency.

커피 자세 coffee.png / coffeeB.png는 생성 이미지의 녹색 배경을 로컬 크로마키 처리로 제거했습니다.

sideWalkA / sideWalkB: 옆모습 보행 두 자세. coffee / coffeeB: 치마 전체가 보이도록 다시 생성한 두 자세. 녹색 배경을 제거하고 캐릭터 주변 투명 여백을 검사했습니다.

1.6: 기존 한복 스타일의 workLaptop/Design/Study/Plan 각 2프레임, walkCycle 4프레임, turnThreeQuarter를 추가했습니다. 직업복 시안은 배포 파일에 포함하지 않았습니다.

1.6.1: 기본 rabbit.png를 색감 기준으로 walkCycle 4프레임, turnThreeQuarter, work 8프레임, coffee 2프레임을 조정했습니다. 녹색 배경을 제거하고 기존 표시 크기에 맞춰 투명 캔버스를 정규화했습니다. pose-preview.png에서 밝고 어두운 배경의 결과를 비교할 수 있습니다.
