document.addEventListener('DOMContentLoaded', () => {
  const buttons = document.querySelectorAll('button.md-clipboard');
  buttons.forEach((btn) => {
    btn.title = 'Copy to clipboard';
  });

  if (window.mermaid) {
    window.mermaid.initialize({
      startOnLoad: true,
      theme: 'base',
      themeVariables: {
        primaryColor: '#00796b',
        secondaryColor: '#00acc1',
        lineColor: '#004d40',
        textColor: '#0b1f24'
      }
    });
  }
});
