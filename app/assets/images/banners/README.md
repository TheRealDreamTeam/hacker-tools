# Banner Images

Place the following banner images in this directory:

1. **eventease.jpg** - EventEase promotional banner (for left banner)
2. **patos-gym.jpg** - Pato's Gym promotional banner (for right banner)
3. **doglog.jpg** - Doglog promotional banner (for left banner)
4. **storypile.jpg** - StoryPile promotional banner (for right banner)

## Image Requirements

- Format: JPG or PNG
- Recommended dimensions: 300x800px (vertical banners)
- The images will be used as background images with a dark overlay gradient

## Usage

The banners are automatically used via the `shared/side_banner` partial:
- Left banners use: `eventease.jpg` or `doglog.jpg`
- Right banners use: `patos-gym.jpg` or `storypile.jpg`

The images are referenced in:
- Homepage (`pages/home.html.erb`)
- Tool show page (`tools/show.html.erb`)
- Submission show page (`submissions/show.html.erb`)

