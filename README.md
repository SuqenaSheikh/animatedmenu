# 🎬 Animated Side Menu

A **Flutter project** showcasing a beautiful **liquid-style animated side menu** with smooth **drag and reveal effects**.  
This project demonstrates how to create visually engaging, gesture-based navigation with Flutter’s animation framework.

---

## 🖼️ Demo

<video src="animatedsidemenu.mp4" controls width="400"></video>

If the video doesn’t play inline, [click here to view it directly](animatedsidemenu.mp4)  
or use this raw GitHub link:  
👉 [Animated Side Menu Demo](https://github.com/SuqenaSheikh/animatedmenu/blob/main/animatedsidemenu.mp4?raw=true)

---

## ✨ Features

- 🎨 **Liquid Reveal Animation** – A wave-like morphing effect for menu reveal.
- 👆 **Edge Drag Detection** – Open menu by dragging from the **left edge** of the screen.
- ⚙️ **Smooth Animation** – Controlled via `AnimationController` and custom `Curve`.
- 📱 **Responsive UI** – Works on Android, iOS, and desktop.
- 🧭 **Menu Toggle Button** – Can open/close programmatically or via icon button.

---

## 🧠 How It Works

The core of the project is a custom **LiquidSideMenu** widget that:
- Uses a **CustomPainter** to render a fluid, animated wave curve.
- Wraps the app’s content inside a **Stack**.
- Listens for horizontal drag gestures to open or close the menu.
- Animates both the curve and menu width using **AnimationController**.

