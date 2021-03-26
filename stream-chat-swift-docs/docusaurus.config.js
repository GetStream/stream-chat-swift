 /** @type {import('@docusaurus/types').DocusaurusConfig} */
module.exports = {
  title: 'StreamChat Swift SDK Docs',
  tagline: '',
  url: 'https://getstream.github.io/stream-chat-swift/',
  baseUrl: '/stream-chat-swift/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'https://getstream.imgix.net/images/favicons/favicon-96x96.png',
  organizationName: 'GetStream',
  projectName: 'stream-chat-swift',
  themeConfig: {
    navbar: {
      title: 'StreamChat Swift SDK Docs',
      logo: {
        alt: 'StreamChat Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          to: 'docs/',
          activeBasePath: 'docs',
          label: 'Docs',
          position: 'left',
        },
        //{to: 'blog', label: 'Blog', position: 'left'},
        {
          href: 'https://github.com/GetStream/stream-chat-swift',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Getting Started',
              to: 'docs/',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'Stack Overflow',
              href: 'https://stackoverflow.com/questions/tagged/stream-chat',
            },
            {
              label: 'Twitter',
              href: 'https://twitter.com/getstream_io',
            },
          ],
        },
        {
          title: 'More',
          items: [
            // {
            //   label: 'Blog',
            //   to: 'blog',
            // },
            {
              label: 'GitHub',
              href: 'https://github.com/GetStream/stream-chat-swift',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Stream.io, Inc. Built with Docusaurus.`,
    },
  },
  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          editUrl:
            'https://github.com/GetStream/stream-chat-swift/edit/main/stream-chat-swift-docs/',
          routeBasePath: '/'
        },
        // blog: {
        //   showReadingTime: true,
        //   // Please change this to your repo.
        //   editUrl:
        //     'https://github.com/GetStream/stream-chat-swift/edit/main/stream-chat-swift-docs/blog/',
        // },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      },
    ],
  ],
};
