# GlowMind UI Refactor Plan

This plan outlines the changes to be implemented to create a more immersive, sticky UI with a realistic heartbeat orb and simplified music controls.

## 1. Structural Navigation Refactor
*   **VerticalMoodNavigator:** 
    *   Move UI elements (small Music Controls, Track Info, Settings/Playlist buttons) from `MoodPage` into a `Stack` overlay in `VerticalMoodNavigator`.
    *   This ensures that while the background and orb scroll vertically as it is (via `PageView`), the control elements remain "sticky" and fixed in place.
*   **MoodPage Cleanup:**
    *   sticky all exiting navigation buttons and controls. not scrolling with orb
    *   Keep only the dynamic background and the centered `MoodOrb`.

## 2. Simplified Music Controls
*   **Player Removal:** Replace the current detailed player with a minimalist control bar.
*   **Buttons:** Include only the following:
    *   Shuffle Toggle
    *   Previous Track
    *   Play/Pause 
    *   Next Track
    *   Mute/Unmute Toggle
*   **Visuals:** Remove the seeker bar, current time, and total duration to reduce visual clutter make it minimalist.

## 3. Enhanced "Heartbeat" Orb
*   **Sizing:** Increase the base size of the `MoodOrb` and ensure it is perfectly centered.
*   **Animation Logic:** keep simple sine-wave pulse heartbeat pattern. with gradient effect
    *   Adjust the "heart rate" based on the current mood (e.g., slow for sleep, faster for party).
*   **Realism:** Add subtle glow intensity shifts that synchronize with the physical expansion of the orb.

## 4. UI Cleanup & Refinement
*   **Information Minimalism:**
    *   Remove all "Swipe up/down" hints and instructions and keep only one in the bottom to swipe up.
    *   Display only one piece of information (Current Track Name) at the bottom of the screen.
*   **Welcome Message:**
    *   Add a "Welcome to GlowMind" transition on the initial app load.
    *   This will be a subtle, fading overlay that appears in `GlowHomePage` when the user first enters the app.

## 5. Review & Implementation
*   [ ] Verify sticky element positioning across different device sizes.
*   [ ] Test the smoothness of the heartbeat animation.
*   [ ] Ensure the mute/unmute functionality correctly updates the `MusicState`.
