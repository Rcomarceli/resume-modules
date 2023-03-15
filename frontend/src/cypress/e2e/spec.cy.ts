describe('E2E testing', () => {

  const domain = Cypress.env('DEV_DOMAIN')

  beforeEach(() => {

    cy.viewport(1280, 1000)

  })

  it('increments the visitor counter', () => {
    
    cy.visit(domain); 


    cy.get('[data-cy="visitorCount"]').contains(/\d+/).then(($count) =>{
        const count1 = parseInt($count.text());
        console.log(count1);
        cy.window().its('API_URL').then(url => {
            cy.request('POST', url).its('body').then(text => parseInt(text)).should('be.gt', count1);
        })

    });
  })


  it('Find all broken links', () => {

    cy.visit(domain); 
    // cy.visit('localhost:5173');

    // get all anchor tags that dont start with "mailto:"
    cy.get('a:not([href*="mailto:"]').each(link => {

      if(link.prop('href').includes('linkedin.com')) {
        cy.request({
          url: link.prop('href'),
          failOnStatusCode: false
        }).its('status').should('be.oneOf', [200, 999]);
      } else if (link.prop('href')) {
        cy.request({
          url: link.prop('href'),
        });
      }

    })
    
  });

  it('Check if project onClick doesnt reveal tooltip for all', () => {
    cy.visit(domain); 
    cy.get('div.card-container:not(:has(div.tooltip))').first().click();

    // shorter timeout since the tooltip disappears after 3500ms;
    cy.get('div[class*="tooltip"]', { timeout: 2500 }).should('not.have.class', 'visible');

  })

  it('Checks if links to section elements work', () =>{
    cy.visit(domain); 

    cy.get('button[class*="nav-toggle"]').click();
    cy.get('a[data-cy="nav-aboutme-link"]').click()
    cy.get('#about-me').should('be.visible');

    cy.get('button[class*="nav-toggle"]').click();
    cy.get('a[data-cy="nav-projects-link"]').click()
    cy.get('#projects').should('be.visible');

  });




})
