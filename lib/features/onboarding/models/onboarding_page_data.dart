class OnboardingPageData {
  final String overTitle;
  final String title;
  final String subtitle;
  final String imagePath;
  final String buttonLabel;
  final String footerLabel;

  const OnboardingPageData({
    required this.overTitle,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.buttonLabel,
    required this.footerLabel,
  });

  static const List<OnboardingPageData> pages = [
    OnboardingPageData(
      overTitle: 'VOTRE PATRIMOINE',
      title: 'Tous vos biens,\nau même endroit',
      subtitle: 'Centralisez vos propriétés, locataires et propriétaires pour tout retrouver en quelques secondes.',
      imagePath: 'assets/images/onboarding_patrimoine.png',
      buttonLabel: 'Suivant',
      footerLabel: 'Simple, sécurisé et pensé pour votre agence',
    ),
    OnboardingPageData(
      overTitle: 'FINANCES EN TEMPS RÉEL',
      title: 'Suivez chaque franc,\nsans effort',
      subtitle: 'Visualisez vos entrées, dépenses et impayés grâce à des indicateurs toujours à jour.',
      imagePath: 'assets/images/onboarding_finances.png',
      buttonLabel: 'Suivant',
      footerLabel: 'Des décisions plus rapides, des finances plus claires',
    ),
    OnboardingPageData(
      overTitle: 'DOCUMENTS AUTOMATISÉS',
      title: 'Générez. Envoyez.\nC\'est réglé.',
      subtitle: 'Créez factures, contrats et quittances mensuelles, puis partagez-les immédiatement.',
      imagePath: 'assets/images/onboarding_documents.png',
      buttonLabel: 'Commencer',
      footerLabel: 'Bienvenue dans une gestion immobilière plus simple',
    ),
  ];
}
