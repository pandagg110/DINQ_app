class HeroContent {
  const HeroContent({
    required this.label,
    required this.titlePrefix,
    required this.titleHighlight,
    required this.titleSecondaryLeft,
    required this.titleSecondaryRight,
    required this.subtitle,
    required this.emailPlaceholder,
    required this.emailCta,
    required this.cards,
  });

  final String label;
  final String titlePrefix;
  final String titleHighlight;
  final String titleSecondaryLeft;
  final String titleSecondaryRight;
  final List<String> subtitle;
  final String emailPlaceholder;
  final String emailCta;
  final List<Map<String, String>> cards;
}

class EmphasisSegment {
  const EmphasisSegment({required this.text, required this.color});

  final String text;
  final String color;
}

class TabContent {
  const TabContent({
    required this.key,
    required this.label,
    required this.emphasisCopy,
    required this.src,
    required this.poster,
    required this.alt,
    this.animationPath,
    this.imagePath,
  });

  final String key;
  final String label;
  final List<List<EmphasisSegment>> emphasisCopy;
  final String src;
  final String poster;
  final String alt;
  final String? animationPath;
  final String? imagePath;
}

class CtaContent {
  const CtaContent({required this.eyebrow, required this.title, required this.buttonLabel, required this.buttonHref});

  final String eyebrow;
  final String title;
  final String buttonLabel;
  final String buttonHref;
}

class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class RoleItem {
  const RoleItem({required this.label, required this.icon});

  final String label;
  final String icon;
}

class ClosingContent {
  const ClosingContent({required this.title, required this.src, required this.poster, required this.alt});

  final String title;
  final String src;
  final String poster;
  final String alt;
}

const HERO = HeroContent(
  label: 'For AI Natives',
  titlePrefix: 'One',
  titleHighlight: 'Card,',
  titleSecondaryLeft: 'All About',
  titleSecondaryRight: 'Me.',
  subtitle: [
    'One card for your profiles and works.',
    'Discover AI talent with natural language.',
  ],
  emailPlaceholder: 'Enter your email',
  emailCta: 'Join Waiting list',
  cards: [
    {
      'heading': 'Signal, not noise',
      'body': 'Curated snapshots of your impact auto-update from the platforms you already use.',
    },
    {
      'heading': 'Instant credibility',
      'body': 'Surface the highlights investors, collaborators, and hiring managers look for in seconds.',
    },
    {
      'heading': 'Ready everywhere',
      'body': 'Share one link across LinkedIn, conferences, or cold outreach and stay in control of the story.',
    },
  ],
);

const EMPHASIS_COPY = {
  'insights': [
    [
      EmphasisSegment(text: 'Your', color: '#30303080'),
      EmphasisSegment(text: ' true self ', color: '#171717'),
      EmphasisSegment(text: 'lives ', color: '#30303080'),
      EmphasisSegment(text: 'not in resumes', color: '#171717'),
      EmphasisSegment(text: ', but in the ', color: '#30303080'),
      EmphasisSegment(text: 'trajectory of action.', color: '#171717'),
    ],
    [
      EmphasisSegment(text: 'DINQ Card traces your ', color: '#30303080'),
      EmphasisSegment(text: 'creative footprint—papers, code, impact—', color: '#171717'),
      EmphasisSegment(text: 'letting ', color: '#30303080'),
      EmphasisSegment(text: 'authentic value ', color: '#171717'),
      EmphasisSegment(text: 'surface naturally.', color: '#30303080'),
    ],
  ],
  'network': [
    [
      EmphasisSegment(text: 'You are not connected by who you know, but by ', color: '#30303080'),
      EmphasisSegment(text: 'what you have built together.', color: '#171717'),
    ],
    [
      EmphasisSegment(text: 'This is the ', color: '#30303080'),
      EmphasisSegment(text: 'network ', color: '#171717'),
      EmphasisSegment(text: 'woven from the ', color: '#30303080'),
      EmphasisSegment(text: 'undeniable ', color: '#171717'),
      EmphasisSegment(text: 'fabric of shared work.', color: '#171717'),
    ],
    [EmphasisSegment(text: 'We make that fabric visible.', color: '#171717')],
  ],
  'opportunities': [
    [
      EmphasisSegment(text: 'The best opportunities ', color: '#171717'),
      EmphasisSegment(text: "aren't ", color: '#30303080'),
      EmphasisSegment(text: 'chased,', color: '#171717'),
      EmphasisSegment(text: " they're ", color: '#30303080'),
      EmphasisSegment(text: 'attracted.', color: '#171717'),
    ],
    [
      EmphasisSegment(text: 'When your ', color: '#30303080'),
      EmphasisSegment(text: 'value ', color: '#171717'),
      EmphasisSegment(text: 'is truly understood, the ', color: '#30303080'),
      EmphasisSegment(text: 'right possibilities ', color: '#171717'),
      EmphasisSegment(text: 'find you.', color: '#30303080'),
    ],
    [
      EmphasisSegment(text: 'This is the ', color: '#30303080'),
      EmphasisSegment(text: 'wisdom shift ', color: '#171717'),
      EmphasisSegment(text: 'from ', color: '#30303080'),
      EmphasisSegment(text: 'pursuit ', color: '#171717'),
      EmphasisSegment(text: 'to ', color: '#30303080'),
      EmphasisSegment(text: 'resonance.', color: '#171717'),
    ],
  ],
};

final List<TabContent> TABS = [
  TabContent(
    key: 'insights',
    label: 'Insights',
    emphasisCopy: EMPHASIS_COPY['insights']!,
    src: '/videos/insights.mp4',
    poster: '/images/insights.jpg',
    alt: 'Analytics dashboard walkthrough',
    imagePath: '/images/landing/2-insight.svg',
  ),
  TabContent(
    key: 'network',
    label: 'Network',
    emphasisCopy: EMPHASIS_COPY['network']!,
    src: '/videos/network.mp4',
    poster: '/images/network.jpg',
    alt: 'Network graph interactions',
    imagePath: '/images/landing/2-network.svg',
  ),
  TabContent(
    key: 'opportunities',
    label: 'Opportunities',
    emphasisCopy: EMPHASIS_COPY['opportunities']!,
    src: '/videos/opportunities.mp4',
    poster: '/images/opportunities.jpg',
    alt: 'Opportunity matching demo',
    animationPath: '/animations/Opportunities.json',
  ),
];

const List<RoleItem> ROLES = [
  RoleItem(label: 'AI Engineer', icon: '/images/landing/3-dev.svg'),
  RoleItem(label: 'Researcher', icon: '/images/landing/3-researcher.svg'),
  RoleItem(label: 'PhD Student', icon: '/images/landing/3-phd.svg'),
  RoleItem(label: 'HR Manager', icon: '/images/landing/3-hr.svg'),
  RoleItem(label: 'Product Manager', icon: '/images/landing/3-pm.svg'),
  RoleItem(label: 'Scientist', icon: '/images/landing/3-sci.svg'),
  RoleItem(label: 'Developer', icon: '/images/landing/3-dev2.svg'),
];

const CTA = CtaContent(
  eyebrow: '',
  title: 'Ready to Show\nYour Best Self?',
  buttonLabel: 'Claim Your DINQ',
  buttonHref: '/apply',
);

const List<FaqItem> FAQ = [
  FaqItem(
    question: 'Who is DINQ for?',
    answer:
        "People who actually build. AI researchers, engineers, founders, and operators who want their work to speak for itself. If LinkedIn feels like a résumé museum, DINQ is more like a live dashboard that shows your momentum.",
  ),
  FaqItem(
    question: 'Is DINQ just another profile page?',
    answer:
        "Nope. It's a living identity, not a static résumé. Every update, publication, or project can flow in automatically — your profile grows as you grow.",
  ),
  FaqItem(
    question: 'Do I need to upload a resume?',
    answer:
        'Optional, not mandatory. Resume, personal site, or LinkedIn — you choose. Connect GitHub, Google Scholar, and more, and DINQ keeps your profile fresh while you keep building.',
  ),
  FaqItem(
    question: 'How is DINQ different from Linktree or Notion?',
    answer:
        'Linktree shows links. Notion shows documents. DINQ shows signal — what you actually do, what you built, and why it matters, all in one link.',
  ),
  FaqItem(
    question: 'Can I customize my DINQ Card?',
    answer:
        'Yes, absolutely. Colors, fonts, layout modules — tweak it until it feels unmistakably yours. Minimalist, loud, academic, hacker-core — all valid styles. You set the vibe.',
  ),
  FaqItem(
    question: 'How do people actually use DINQ?',
    answer:
        'One link. Many moments. Share it in intros, DMs, hiring processes, or collaboration invites — let it speak for you. No more juggling multiple links or explaining your work in paragraphs.',
  ),
  FaqItem(
    question: 'Is DINQ only for job hunting?',
    answer:
        "Not at all. DINQ is for anyone who wants to be discovered — by collaborators, recruiters, or fellow builders. It's about showing signal, not asking for attention.",
  ),
  FaqItem(
    question: 'Can I find other people on DINQ?',
    answer:
        "Yes. Search AI-native talent using prompts instead of clunky filters. Want 'video generation researchers in the Bay Area'? DINQ surfaces them instantly.",
  ),
  FaqItem(
    question: 'Is DINQ mobile-friendly?',
    answer:
        'Absolutely. Your DINQ Card looks sharp and scrolls smoothly on any device. Plus, our mobile app is coming soon to all major app stores — even easier to share on the go.',
  ),
  FaqItem(
    question: 'What is DINQ in one line?',
    answer:
        "DINQ is proof you're real — online. It's a living card, a showcase of work, and a hub for connection, all in one.",
  ),
];

const CLOSING = ClosingContent(
  title: 'Built for the people building what is next',
  src: '/videos/closing.mp4',
  poster: '/images/closing.jpg',
  alt: 'Overview video of DINQ card experience',
);


