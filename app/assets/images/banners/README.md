# Banner Images

The following banner images are in this directory:

1. **eventease-banner.png** - EventEase promotional banner
2. **pato-gym.png** - Pato's Gym promotional banner
3. **doglog-banner.png** - Doglog promotional banner
4. **storypile-banner.png** - StoryPile promotional banner

## Image Requirements

- Format: PNG
- Dimensions: ~300x900px (vertical banners, aspect ratio ~1:3)
- Images are displayed in full without cropping

## Usage

The banners are automatically used via the `shared/side_banner` partial:
- Images are randomly selected and displayed on left and right sides
- Left and right banners always show different images
- Images are displayed with rounded corners and 3D effects

The images are referenced in:
- Homepage (`pages/home.html.erb`)
- Tool show page (`tools/show.html.erb`)
- Submission show page (`submissions/show.html.erb`)

