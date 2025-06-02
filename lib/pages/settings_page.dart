import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  final AppUser? currentUser;
  final VoidCallback? onAuthRequired;
  final VoidCallback? onLogout;

  const SettingsPage({
    Key? key,
    this.currentUser,
    this.onAuthRequired,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isGuest = currentUser?.isGuest ?? true;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // User Profile Section
          if (!isGuest) ...[
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.primaryColor,
                    child: Text(
                      currentUser?.userName?.substring(0, 1).toUpperCase() ??
                          'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.userName ?? 'User',
                          style: TextStyle(
                            color: theme.textTheme.titleLarge?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'User ID: ${currentUser?.userId ?? 'N/A'}', // Show user ID instead of email
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            currentUser?.userType.displayName ?? 'User',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],

          // Theme Section
          _buildSectionTitle(context, 'Appearance'),
          SizedBox(height: 12),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      title: 'Theme',
                      subtitle: themeProvider.isDarkMode
                          ? 'Dark Mode'
                          : 'Light Mode',
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                        activeColor: theme.primaryColor,
                      ),
                      onTap: () {
                        themeProvider.toggleTheme();
                      },
                    ),
                    Divider(height: 1, color: theme.dividerColor),
                    _buildSettingsTile(
                      context,
                      icon: Icons.palette_outlined,
                      title: 'Theme Options',
                      subtitle: 'Customize app appearance',
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _showThemeOptions(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 24),

          // Account Section
          _buildSectionTitle(context, 'Account'),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (isGuest) ...[
                  _buildSettingsTile(
                    context,
                    icon: Icons.login,
                    title: 'Sign In',
                    subtitle: 'Access your account',
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: onAuthRequired,
                  ),
                ] else ...[
                  _buildSettingsTile(
                    context,
                    icon: Icons.person_outline,
                    title: 'Profile',
                    subtitle: 'View your profile information',
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showProfileDialog(context);
                    },
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _buildSettingsTile(
                    context,
                    icon: Icons.security,
                    title: 'Privacy & Security',
                    subtitle: 'Manage your privacy settings',
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: Navigate to privacy settings
                    },
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _buildSettingsTile(
                    context,
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Sign out of your account',
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 24),

          // App Section
          _buildSectionTitle(context, 'App'),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to notification settings
                  },
                ),
                Divider(height: 1, color: theme.dividerColor),
                _buildSettingsTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to help
                  },
                ),
                Divider(height: 1, color: theme.dividerColor),
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'App version and information',
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: theme.textTheme.headlineSmall?.color,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.primaryColor, // This will change with theme
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              theme.textTheme.titleMedium?.color, // This will change with theme
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color:
              theme.textTheme.bodySmall?.color, // This will change with theme
          fontSize: 12,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showProfileDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Profile Information',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('Username', currentUser?.userName ?? 'N/A', theme),
            SizedBox(height: 12),
            _buildProfileRow(
              'Email',
              currentUser?.email?.toString() ?? 'N/A',
              theme,
            ),
            SizedBox(height: 12),
            _buildProfileRow(
              'Status',
              currentUser?.isGuest == true ? 'Guest' : 'Registered',
              theme,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
        ),
      ],
    );
  }

  void _showThemeOptions(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Theme',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.brightness_auto,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                'System Default',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              trailing: themeProvider.themeMode == ThemeMode.system
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                themeProvider.setTheme(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.light_mode,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                'Light Mode',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              trailing: themeProvider.themeMode == ThemeMode.light
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                themeProvider.setTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.dark_mode,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              trailing: themeProvider.themeMode == ThemeMode.dark
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                themeProvider.setTheme(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Sign Out',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onLogout?.call();
            },
            child: Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          '1337 Events',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version: 1.0.0',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            SizedBox(height: 8),
            Text(
              'A modern event management app for the 1337 community.',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }
}
