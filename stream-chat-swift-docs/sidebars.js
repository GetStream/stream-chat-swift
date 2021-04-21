module.exports = {
  docs: [
    'home',
    'introduction',
    {
      type: 'category',
      label: 'Guides',
      items: [
        'guides/integration',
        'guides/getting-started',
        'guides/working-with-channel-list',
        'guides/working-with-a-channel',
        'guides/working-with-messages',
        'guides/working-with-user',
        'guides/pinned-messages',
        'guides/working-with-attachments',
        'guides/working-with-reactions',
        'guides/working-with-members',
        'guides/working-with-watchers',
        'guides/events',
        'guides/push-notifications',
        'guides/connection-status',
        'guides/ui-customization',
        'guides/moderation',
        'guides/filter-query-guide',
        'guides/multi-tenancy',
        'guides/debugging',
      ],
    },
    {
      type: 'category',
      label: 'StreamChat Controllers',
      items: [
        'controllers/controllers-overview',
      ],
    },
    {
      type: 'category',
      label: 'UI Components',
      items: [
        'ui-components/ui-components-overview',
      ],
    },
    'migrating-from-1.x-and-2.x',
    'faq',
    'glossary'
  ],
};
