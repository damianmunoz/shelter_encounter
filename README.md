Shelter Encounter

Shelter Encounter is a top-down action survival game built with Flutter and Flame, where players fend off waves of enemies in a shelter environment. The game features simple controls, dynamic enemy waves, and an evolving difficulty curve. This project is an MVP intended for iOS devices, developed as part of a mobile applications class.

Table of Contents

Overview
Features
Technologies
Setup Instructions
Gameplay
Future Improvements
License
Overview

In Shelter Encounter, players navigate a shelter environment, defending against enemies that break through barricades in waves. The game tests the player's ability to survive as long as possible, with each wave increasing in difficulty.

This project aims to provide a retro, Undertale-inspired look and feel, with pixel-art graphics, simple animations, and engaging gameplay mechanics.

Features

Wave-Based Enemy Spawning: Enemies spawn from barricaded windows and doors and attempt to reach the player.
Dynamic Camera: The player explores various rooms (kitchen, main room, etc.), with a camera that follows the player’s movement.
Simple Controls and HUD: Easy-to-use touch controls, along with HUD elements to display health, score, and wave information.
Audio and Visual Effects: Retro-style sound effects and animations to enhance the immersive experience.
Technologies

Flutter: For cross-platform mobile development, optimized for iOS.
Flame: A game engine built for Flutter to handle 2D graphics, sprites, and animations.
Flame Audio: For background music and sound effects.
Git: Version control for project management.
Firebase (optional): For potential high scores, leaderboards, or other cloud-synced features.
Setup Instructions

Clone the Repository:
git clone https://github.com/damianmunoz/shelter_encounter.git
cd shelter_encounter
Install Flutter Dependencies:
Ensure Flutter is installed on your system. Then, run:
flutter pub get
Configure Firebase (Optional):
If using Firebase for leaderboards or high scores, configure it as per Firebase's setup instructions.
Run the App:
For iOS:
flutter run
Ensure Xcode and CocoaPods are installed if deploying on an iOS device or simulator.
Gameplay

Objective: Survive as long as possible by defending against waves of enemies.
Enemies: Each wave brings more challenging enemies that spawn from windows and doors, requiring the player to strategize and survive.
Controls: Simple touch controls to move the player character within the shelter.
Scoring: Players earn points for each wave completed, with a potential leaderboard option via Firebase.
Future Improvements

Additional Enemy Types: Introducing different enemy types to diversify gameplay.
Weapon and Item Mechanics: Implementing weapons or items that the player can use for enhanced defense.
Multiplayer Mode: Potential feature to allow cooperative gameplay.
Additional Levels: Expanding the shelter layout to include more complex rooms and challenges.
License

This project is licensed under the MIT License - see the LICENSE file for details.
