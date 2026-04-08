<div align="center">

<img src="assets/logo_github.png" alt="Kolirus — Mediterranean ancestral eating" width="100%">

# Kolirus

**Eat the same way your Mediterranean ancestors ate.**

</div>

---

## Overview

Kolirus is a food organization app that helps you keep track of what you buy, what you eat, and what needs to be used before it expires.

It combines pantry tracking, meal logging, shopping lists, recipes, and health insights so you can waste less food and build healthier habits over time. The app also supports diet guidance, including Mediterranean-style eating patterns built around whole foods, olive oil, legumes, vegetables, fish, and simple home-cooked meals.

## What Kolirus Helps With

- Track food items in your pantry and fridge
- See what is close to its expiry date
- Log meals and eating habits
- Build shopping lists from what you already have
- Discover recipes and routine ideas
- Follow healthier eating patterns, including a Mediterranean diet

## Core Features

- **Pantry management** to keep an inventory of food at home
- **Food expiry tracking** with daily notifications for each of the 5 days before expiry
- **Meal logging** to record what you eat day by day
- **Shopping list tools** to plan what you need next
- **Recipe browsing** for meal inspiration
- **Health and nutrition tracking** for trends over time
- **BMI gauge** with visual healthy/overweight/obese indicators
- **Streak tracking** for healthy eating, no food waste, and addiction-free days
- **Scanner support** to quickly add items via barcode
- **Custom diet filters** to define your own dietary rules by ingredient keywords
- **Notifications** to remind you about important food dates

## Built With

- Flutter
- Riverpod
- SQLite (sqflite)
- Mobile scanner support
- Local notifications
- Charts and nutrition utilities (fl_chart)

## Data Sources

Product nutritional data is powered by **[Open Food Facts](https://world.openfoodfacts.org/)** — a free, open, collaborative database of food products from around the world. Open Food Facts is available under the [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/1-0/).

The Open Food Facts database is maintained by a community of volunteers. You can contribute to it at [openfoodfacts.org](https://world.openfoodfacts.org/).

## Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- Dart SDK
- Android Studio, VS Code, or another Flutter-compatible editor
- An Android emulator, iOS simulator, or a physical device

### Installation
```bash
git clone https://github.com/Edwiyyin/Kolirus.git
cd Kolirus
flutter pub get
```

### Run / Develop
```bash
flutter run
```

To analyze or test:
```bash
flutter analyze
flutter test
```

## Usage

1. Add the food you already have at home (manually or via barcode scan).
2. Set expiry dates — you will receive a notification every day for each of the 5 days before the item expires.
3. Log meals to understand your eating habits.
4. Build a shopping list around what you need, not what you already own.
5. Use the recipe and diet tools to move toward a healthier pattern.
6. Set dietary preferences, religious diet rules, or create your own custom filter based on ingredient keywords.

## Expiry Notifications

Kolirus schedules one notification per day for each of the 5 days leading up to an item's expiry date, sent at 9:00 AM. You will receive a reminder on days 5, 4, 3, 2, 1, and 0 (the day of expiry). Notification banners appear on the lock screen and status bar.

## Google Sign-In / Cloud Sync

Currently, all data is stored locally on-device using SQLite. To enable Google Sign-In and cloud sync:

1. Create a Firebase project and add your app's SHA-1 fingerprint.
2. Download `google-services.json` and place it in `android/app/`.
3. Integrate Firebase Firestore to sync data across devices.

## Why It Exists

Food waste usually happens when ingredients are forgotten, expiry dates are missed, or shopping is repeated without checking what is already in the kitchen. Kolirus fixes this by keeping food inventory, meal tracking, and diet guidance in one place.

## Roadmap

- [ ] Cloud sync via Firebase Firestore
- [ ] Smarter pantry sorting and filtering
- [ ] Expand recipe recommendations based on pantry items
- [ ] More nutrition and habit insights
- [ ] Clearer onboarding flow for new users
- [ ] iOS Health app integration

## Contributing

Contributions are welcome.

1. Fork the repo
2. Create a branch: `git checkout -b feature/my-change`
3. Commit your changes: `git commit -m "Add my change"`
4. Push to your fork: `git push origin feature/my-change`
5. Open a Pull Request

## License

MIT License. See `LICENSE` file.

---

**Kolirus — Waste less food, eat better, and stay organized.**

---

*Nutritional data provided by [Open Food Facts](https://world.openfoodfacts.org/) under the [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/1-0/).*