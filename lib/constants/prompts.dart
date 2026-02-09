class PromptTemplate {
  PromptTemplate({
    required this.id,
    required this.title,
    required this.content,
  });

  final String id;
  final String title;
  final String content;
}

final List<PromptTemplate> promptTemplates = [
  PromptTemplate(
    id: '1',
    title: 'Find Video Gen AI Researchers',
    content: '''Find AI researchers in video generation.
Location: San Francisco Bay Area
Focus areas:
- Diffusion models
- Multimodal models
- Text-to-video / image-to-video
Preference: Hands-on production or research experience''',
  ),
  PromptTemplate(
    id: '2',
    title: 'Find Tech Lead / CTO for AI Startup',
    content: '''Find Tech Lead or CTO candidates for early-stage AI startup.
Background: Top-tier tech companies (FAANG, etc.)
Requirements:
- Full-stack engineering
- System architecture expertise
- AI product experience
Preference: Startup mindset, hands-on leadership''',
  ),
  PromptTemplate(
    id: '3',
    title: 'Find GTM Experts for AI Products',
    content: '''Find GTM experts for AI agent products.
Focus areas:
- Product-led growth
- Developer adoption strategies
- Early-stage scaling
Product type: AI-native or developer tools
Preference: Proven track record in growth''',
  ),
  PromptTemplate(
    id: '4',
    title: 'Find Young AI Researchers (Shunyu Yao style)',
    content: '''Find young AI research scientists similar to Shunyu Yao.
Profile: PhD-level, early career
Expertise:
- Foundational models
- Advanced AI research
Location: US or China
Preference: Chinese background preferred''',
  ),
  PromptTemplate(
    id: '5',
    title: 'Identify High-Potential AI Research Talent',
    content: '''Identify high-potential AI research talents.
Stage: Early-career but fast-rising
Signals:
- Strong publications
- Open-source impact
- Top AI lab experience
Location: US or China''',
  ),
  PromptTemplate(
    id: '6',
    title: 'Find AI Talents with Founder Signals',
    content: '''Find AI talents likely to start companies in 2026.
Current employers: Meta, ByteDance (Bay Area), xAI
Roles: Algorithm, SWE, PM, or GTM
Signals:
- Side projects
- Public thought leadership
- Startup discussions''',
  ),
  PromptTemplate(
    id: '7',
    title: 'Find Manus AI Core Team',
    content: '''Find core team members of Manus AI.
Roles to identify:
- Founders / Co-founders
- Senior technical leaders
- Product leaders
Output: Roles, backgrounds, key contributions
Focus: Core contributors to the product''',
  ),
  PromptTemplate(
    id: '8',
    title: 'Find Applied AI Engineers',
    content: '''Find applied AI engineers who ship products.
Experience:
- LLM applications
- AI agents
- Production-grade systems
Background: Startup or industry experience
Preference: Strong execution over pure academia''',
  ),
  PromptTemplate(
    id: '9',
    title: 'Find AI Infra / ML Systems Engineers',
    content: '''Find AI infrastructure engineers.
Expertise:
- Large-scale model training
- Inference optimization
- Distributed systems / LLM serving
Focus: Performance, scalability, cost-efficiency
Preference: Production system experience''',
  ),
  PromptTemplate(
    id: '10',
    title: 'Find AI Startup Operators (1→10 Stage)',
    content: '''Find operators who scaled AI startups from 1 to 10.
Stage: Early PMF to Series A/B
Roles:
- Early engineer
- Head of Engineering
- Head of Product
Traits: Strong ownership, high execution capability''',
  ),
  PromptTemplate(
    id: '11',
    title: 'Find Vertical AI Domain Experts',
    content: '''Find AI talents with deep domain expertise.
Domains:
- Healthcare, Finance, Manufacturing
- Gaming, Education, Design
Requirements: AI + domain combination
Experience: Built or deployed real solutions
Preference: Industry practitioners over generalists''',
  ),
  PromptTemplate(
    id: '12',
    title: 'Find AI Open-source & Community Leaders',
    content: '''Find AI developers with community influence.
Signals:
- Open-source maintainers
- Active GitHub contributors
- Thought leaders on X / blogs
Impact: Drive adoption and trust
Community: Developer-focused audiences''',
  ),
  PromptTemplate(
    id: '13',
    title: 'Find AI Talents Ready to Leave Big Tech',
    content: '''Find AI talents showing transition signals.
Indicators:
- Active side projects
- Open-source leadership
- Public writing about independence
Current status: At large tech companies
Prediction: Likely to leave soon''',
  ),
];
