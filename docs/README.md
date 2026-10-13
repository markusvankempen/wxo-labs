# WXO Labs Tutorial - GitHub Pages

This directory contains the GitHub Pages website for the WXO Labs & Tutorial Guide.

## 🌐 Live Site

Once deployed, the site will be available at:
`https://[your-username].github.io/WxO-ToolBox/`

## 📁 Files

- **index.html** - Main landing page with all 12 labs
- **styles.css** - Modern, responsive styling with IBM Carbon Design System inspiration
- **script.js** - Interactive features and animations
- **README.md** - This file

## 🚀 Deployment Instructions

### Option 1: GitHub Pages (Recommended)

1. **Enable GitHub Pages:**
   - Go to your repository settings
   - Navigate to "Pages" section
   - Under "Source", select the branch (usually `main` or `master`)
   - Set the folder to `/docs`
   - Click "Save"

2. **Wait for deployment:**
   - GitHub will automatically build and deploy your site
   - This usually takes 1-2 minutes
   - You'll see a green checkmark when it's ready

3. **Access your site:**
   - Visit `https://[your-username].github.io/[repository-name]/`

### Option 2: Custom Domain

If you have a custom domain:

1. Add a `CNAME` file to the `/docs` directory:
   ```
   your-domain.com
   ```

2. Configure DNS settings with your domain provider:
   - Add a CNAME record pointing to `[your-username].github.io`

3. Enable "Enforce HTTPS" in repository settings

## 🎨 Features

### Modern Design
- ✅ Responsive layout (mobile, tablet, desktop)
- ✅ Smooth scrolling navigation
- ✅ Animated card hover effects
- ✅ Progress indicator
- ✅ Glassmorphism effects

### Interactive Elements
- ✅ Scroll-based animations
- ✅ Active navigation highlighting
- ✅ Mobile menu toggle
- ✅ Keyboard shortcuts (h = home, / = search)
- ✅ Accessibility features (skip links, ARIA labels)

### Performance
- ✅ Optimized CSS with CSS variables
- ✅ Lazy loading animations
- ✅ Minimal JavaScript dependencies
- ✅ Fast page load times

## 🛠️ Customization

### Colors

Edit CSS variables in `styles.css`:

```css
:root {
    --primary: #0f62fe;
    --secondary: #8a3ffc;
    --success: #24a148;
    /* ... more colors */
}
```

### Content

Edit `index.html` to:
- Update lab descriptions
- Add new sections
- Modify hero content
- Change footer information

### Functionality

Edit `script.js` to:
- Add search functionality
- Implement filters
- Add analytics tracking
- Customize animations

## 📱 Browser Support

- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

## 🔧 Local Development

To test locally:

1. **Simple HTTP Server (Python):**
   ```bash
   cd docs
   python3 -m http.server 8000
   ```
   Visit: `http://localhost:8000`

2. **VS Code Live Server:**
   - Install "Live Server" extension
   - Right-click `index.html`
   - Select "Open with Live Server"

3. **Node.js HTTP Server:**
   ```bash
   npx http-server docs -p 8000
   ```

## 📊 Analytics (Optional)

To add Google Analytics:

1. Get your GA4 tracking ID
2. Add to `index.html` before `</head>`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

## 🐛 Troubleshooting

### Site not loading
- Check that GitHub Pages is enabled in settings
- Verify the correct branch and folder are selected
- Wait a few minutes for deployment to complete

### Styles not applying
- Clear browser cache
- Check browser console for errors
- Verify `styles.css` path is correct

### JavaScript not working
- Check browser console for errors
- Ensure `script.js` is loaded
- Verify browser supports ES6+

## 📝 Future Enhancements

Potential additions:
- [ ] Individual lab detail pages
- [ ] Search functionality
- [ ] Dark mode toggle
- [ ] Progress tracking (localStorage)
- [ ] Lab completion badges
- [ ] Interactive code playgrounds
- [ ] Video tutorials
- [ ] Community comments section

## 🤝 Contributing

To contribute improvements:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## 📄 License

This documentation is part of the WXO Test Tools & Patterns Library.

---

**Author:** Markus van Kempen | [mvk@ca.ibm.com](mailto:mvk@ca.ibm.com) | [markus.van.kempen@gmail.com](mailto:markus.van.kempen@gmail.com)  
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)  
*No bug too small, no syntax too weird.*