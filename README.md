# Asia Fibernet App

A comprehensive Flutter application for Asia Fibernet's internet service management, providing separate interfaces for customers and technicians with role-based access control.

## 🚀 Features

### Customer Features
- **Authentication**: Secure login with OTP verification
- **Dashboard**: Personalized home screen with service overview
- **Bill Payment**: Quick bill payment functionality
- **Speed Test**: Internet speed testing capabilities
- **Usage Tracking**: Data usage monitoring and analytics
- **Support**: Customer complaints and support system
- **Referral Program**: Referral management system
- **KYC Verification**: Document verification status
- **BSNL Plans**: Premium plan management

### Technician Features
- **Dashboard**: Technician-specific dashboard with task overview
- **Ticket Management**: View and manage service tickets
- **Customer Management**: Access to customer details and information
- **Expense Tracking**: Expense management and reporting
- **Attendance**: Attendance tracking system
- **Notifications**: Real-time notifications and updates
- **Profile Management**: Technician profile and settings

### General Features
- **Role-Based Access**: Secure authentication with customer/technician roles
- **Real-time Notifications**: Local notifications for important updates
- **Responsive Design**: Optimized for various screen sizes
- **Offline Support**: Basic offline functionality
- **Modern UI**: Clean, intuitive interface with Material Design

## 🛠️ Tech Stack

- **Framework**: Flutter 3.7.0+
- **State Management**: GetX
- **Navigation**: GetX Navigation
- **Local Storage**: SharedPreferences, Flutter Secure Storage
- **HTTP Client**: HTTP package
- **Location Services**: Geolocator, Geocoding
- **Notifications**: Flutter Local Notifications
- **UI Components**: Material Design, Custom components
- **Fonts**: Google Fonts (Poppins)
- **Charts**: Syncfusion Flutter Charts
- **PDF Generation**: PDF and Printing packages

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Web (with limitations)

## 🔧 Installation

### Prerequisites
- Flutter SDK 3.7.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Xcode (for iOS development)

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd asia_fibernet
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   - Update API endpoints in `lib/src/services/apis/`
   - Configure notification settings
   - Set up location permissions

4. **Run the application**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```
lib/
├── main.dart                          # App entry point
├── src/
│   ├── app.dart                       # App configuration
│   ├── auth/                          # Authentication module
│   │   ├── core/
│   │   │   ├── controller/            # Auth controllers & bindings
│   │   │   └── model/                 # Auth data models
│   │   └── ui/                        # Auth UI screens
│   ├── customer/                      # Customer module
│   │   └── ui/screen/                 # Customer screens
│   ├── technician/                    # Technician module
│   │   └── ui/screens/                # Technician screens
│   ├── services/                      # Core services
│   │   ├── apis/                      # API services
│   │   ├── auth_middleware/           # Route protection middleware
│   │   ├── routes.dart                # App routing
│   │   └── sharedpref.dart            # Local storage
│   └── theme/                         # App theming
│       ├── colors.dart                # Color definitions
│       └── theme.dart                 # Theme configuration
```

## 🔐 Authentication & Security

### Authentication Flow
1. **Phone Number Input**: User enters mobile number
2. **OTP Verification**: SMS-based OTP verification
3. **Role Assignment**: Automatic role detection (customer/technician)
4. **Dashboard Redirect**: Role-based dashboard navigation

### Security Features
- **JWT Token Management**: Secure token storage and validation
- **Route Protection**: Middleware-based route protection
- **Role-Based Access**: Granular permission system
- **Secure Storage**: Encrypted local storage for sensitive data

## 🛡️ Middleware System

The app implements a comprehensive middleware system for route protection:

### AuthMiddleware
- Validates user authentication status
- Redirects unauthenticated users to login
- Prevents authenticated users from accessing auth screens

### RoleMiddleware
- Enforces role-based access control
- Separates customer and technician routes
- Redirects unauthorized role access

## 📡 API Integration

- **Base API Service**: Centralized HTTP client with error handling
- **Authentication APIs**: Login, OTP verification, token management
- **Customer APIs**: Service management, billing, support
- **Technician APIs**: Ticket management, customer data, reporting

## 🎨 UI/UX Features

- **Responsive Design**: Adaptive layouts for different screen sizes
- **Material Design**: Consistent with Google's design guidelines
- **Custom Components**: Reusable UI components
- **Animations**: Smooth transitions and micro-interactions
- **Dark Mode Ready**: Theme system supports dark mode

## 📦 Dependencies

### Core Dependencies
- `get: ^4.7.2` - State management and navigation
- `flutter_screenutil: ^5.9.3` - Responsive design
- `google_fonts: ^6.2.1` - Typography
- `shared_preferences: ^2.5.3` - Local storage
- `http: ^1.4.0` - HTTP client

### Feature Dependencies
- `flutter_local_notifications: ^19.4.0` - Local notifications
- `geolocator: ^14.0.2` - Location services
- `image_picker: ^1.0.4` - Image selection
- `syncfusion_flutter_charts: ^30.2.7` - Data visualization
- `pdf: ^3.11.3` - PDF generation

## 🚀 Build & Deployment

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🔧 Configuration

### Environment Setup
1. **API Configuration**: Update base URLs in API services
2. **Notification Setup**: Configure Firebase/APNs for push notifications
3. **Location Permissions**: Set up location access permissions
4. **Security**: Configure JWT token settings

### Customization
- **Branding**: Update colors, logos, and branding elements
- **Features**: Enable/disable specific features
- **API Endpoints**: Configure backend service URLs

## 📱 Screenshots

*Add screenshots of the app here*

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is proprietary software developed for Asia Fibernet. All rights reserved.

## 📞 Support

For technical support or questions:
- **Email**: support@asiafibernet.com
- **Phone**: [Support Number]
- **Documentation**: [Link to detailed documentation]

## 🔄 Version History

- **v1.0.0** - Initial release with core customer and technician features
- **v1.0.1** - Bug fixes and performance improvements
- **v1.1.0** - Added middleware system and enhanced security

---

**Asia Fibernet** - Connecting you to the future of internet services.# Asia-Fibernet
