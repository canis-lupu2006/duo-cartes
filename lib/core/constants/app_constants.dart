class AppConstants {
  static const String appName = 'DuoCartes';
  static const String inviteScheme = 'duocartes';
  static const String inviteHost = 'join';
  static const int whotInitialHandSize = 6;
  static const String roomsCollection = 'rooms';

  /// Lien partageable : duocartes://join/<roomId>
  static String inviteLink(String roomId) =>
      '$inviteScheme://$inviteHost/$roomId';
}
