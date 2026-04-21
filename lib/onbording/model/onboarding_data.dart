class OnboardingModel {
  final String image;
  final String title;
  final String description;

  final bool isLast;

  OnboardingModel({
    required this.image,
    required this.title,
    required this.description,

    required this.isLast,
  });
}

final List<OnboardingModel> onboardingList = [
  //pic onbording 1
  OnboardingModel(
    image: 'assets/PNG/doctor-patient 1.png',
    title: 'Welcome \nTo VitaGuard',
    description:
        'Track symptoms, monitor breathing, and get expert medical guidance.',

    isLast: false,
  ),

  //pic onbording 2
  OnboardingModel(
    image: 'assets/PNG/medical-record 2.png',
    title: 'Monitor Your\nSymptoms Easily',
    description:
        'Record cough, fever, and breathing difficulty to help your doctor follow your condition.',

    isLast: false,
  ),

  //pic onbording 3
  OnboardingModel(
    image: 'assets/PNG/doctor_3.png',
    title: 'Stay Connected \nWith your Doctor',
    description:
        'Your doctor can view your progress and give you recommended steps.',

    isLast: false,
  ),

  //pic onbording 4
  OnboardingModel(
    image: 'assets/PNG/youth_14.png',
    title: 'Support Your\nLoved Ones',
    description:
        'As a companion, you can follow the patient’s symptoms, receive alerts, and help them stay on track.',

    isLast: false,
  ),

  //pic onbording 5
  OnboardingModel(
    image: 'assets/PNG/medical_5.png',
    title: 'For Healthcare\nFacilities',
    description:
        'Built for healthcare facilities to enhance workflow and patient care.',

    isLast: true,
  ),
];
