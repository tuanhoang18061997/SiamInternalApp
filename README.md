# Siam Internal App

An internal employee leave request management application built with Flutter.

## Features

- **User Authentication**: Login system with role-based access (Employee/Manager)
- **Leave Request Management**: Create, view, and manage leave requests
- **Approval Workflow**: Managers can approve or reject leave requests
- **Clean Architecture**: Well-organized code structure with separation of concerns
- **State Management**: Riverpod for efficient state management
- **Navigation**: go_router for declarative routing
- **Mock API**: Built-in mock data source for testing

## Architecture

The app follows Clean Architecture principles with the following structure:

```
lib/
├── core/               # Core utilities and constants
│   ├── constants/      # App and API constants
│   ├── network/        # Dio HTTP client setup
│   └── utils/          # Helper utilities
├── data/               # Data layer
│   ├── datasources/    # Mock API and remote data sources
│   ├── models/         # Data models with JSON serialization
│   └── repositories/   # Repository implementations
├── domain/             # Domain layer
│   ├── entities/       # Business entities
│   ├── repositories/   # Repository interfaces
│   └── usecases/       # Business logic use cases
├── presentation/       # Presentation layer
│   ├── providers/      # Riverpod providers
│   ├── screens/        # UI screens
│   └── widgets/        # Reusable widgets
└── routes/             # App routing configuration
```

## Tech Stack

- **Flutter**: Stable channel with Dart 3
- **State Management**: flutter_riverpod ^2.4.9
- **Routing**: go_router ^13.0.0
- **Networking**: dio ^5.4.0
- **Environment Variables**: flutter_dotenv ^5.1.0
- **Code Generation**: freezed, json_serializable

## Getting Started

### Prerequisites

- Flutter SDK (stable channel, Dart 3+)
- Dart SDK >=3.0.0 <4.0.0

### Installation

1. Clone the repository:
```bash
git clone https://github.com/tuanhoang18061997/SiamInternalApp.git
cd SiamInternalApp
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code for freezed and json_serializable:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Create a `.env` file from the example:
```bash
cp .env.example .env
```

5. Run the app:
```bash
flutter run
```

## Demo Credentials

The app includes mock users for testing:

**Manager Account:**
- Email: `admin@siam.com`
- Password: `any` (any password works with mock API)
- Role: Manager (can approve/reject requests)

**Employee Account:**
- Email: `employee@siam.com`
- Password: `any` (any password works with mock API)
- Role: Employee (can create requests)

## Usage

### For Employees

1. **Login**: Use employee credentials to log in
2. **View Requests**: See all your leave requests on the home screen
3. **Create Request**: Tap the "New Request" button to create a leave request
4. **Fill Details**: Select leave type, dates, and provide a reason
5. **Submit**: Submit the request for manager approval
6. **Track Status**: View request status (Pending/Approved/Rejected)

### For Managers

1. **Login**: Use manager credentials to log in
2. **Review Requests**: See all employee leave requests
3. **View Details**: Tap on a request to see full details
4. **Take Action**: Approve or reject pending requests
5. **Provide Feedback**: Add rejection reason when rejecting requests

## Development

### Code Generation

When modifying models or entities with freezed/json_serializable annotations:

```bash
flutter pub run build_runner watch
```

### Linting

```bash
flutter analyze
```

### Testing

```bash
flutter test
```

## CI/CD

The project includes GitHub Actions workflows for:

- **Code Analysis**: Runs `flutter analyze` on every push
- **Testing**: Runs `flutter test` on every push

See `.github/workflows/` for workflow configurations.

## Environment Variables

Copy `.env.example` to `.env` and configure:

- `API_BASE_URL`: Base URL for the API (currently using mock)
- `ENV`: Environment (development/staging/production)
- `ENABLE_MOCK_API`: Toggle mock API on/off

## Project Structure Details

### Core Layer
- Constants for API endpoints and app-wide values
- Dio client configuration for HTTP requests
- Utility functions and helpers

### Data Layer
- Mock data source simulating API responses
- Data models with JSON serialization
- Repository implementations bridging data and domain layers

### Domain Layer
- Pure business entities using freezed for immutability
- Repository interfaces defining contracts
- Use cases for business logic (can be added as needed)

### Presentation Layer
- Riverpod providers for state management
- Screens for different features
- Reusable widgets and components

## Future Enhancements

- [ ] Real API integration
- [ ] Push notifications for request updates
- [ ] Leave balance tracking
- [ ] Calendar view for leave schedules
- [ ] Export reports
- [ ] Multi-language support
- [ ] Dark theme support
- [ ] Offline support with local database

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is proprietary software for internal use only.

## Contact

For questions or support, please contact the development team.
