# global-redirects-brb

This repo hosts a static page that provides a generic "Page Unavailable" message.  

There are 2 options to using this repo:

1.  Redirect to generic "be right back" page found here:  https://brb.p4.greenpeace.org/index.html

	a.  Redirect your domain to this URL as a CNAME

2.  Create a specific page and redirect your site to this page.

	a.  Create a single HTML page containing the information needed.  Hint:  if you want to include images stick them in a google bucket and point to them.

	b.  Upload your HTML page to this repo in the public folder, call it something relevant to your requirement.  In this example we have one called something.html.

	c.  Add a redirect to this repo: https://github.com/greenpeace/global-redirects by adding the relevant details to the dev.sites.json file per this example:

  {
    "owners": [
      {
       "name": "Contact for Redirect",
       "email": "someone@greenpeace.org",
       "unit": "GP Somewhere"
      }
    ],
    "from": "somthing.com",
    "to": "https://brb.p4.greenpeace.org/something.html"
  }

  This will create an ingress for the nginx service.

	d.  Point your DNS for the source site to this IP:

| DNS name | Type | TTL | Data |
| ------------- | ------ |------ |------ |
| somthing.com      | A | 300 | 35.238.108.93 |

  This should generate a certificate for this URL and redirect it once the DNS has updated.

At this stage all commits to the develop pipeline complete the work required.  

> NB:  This has not been deployed to P4 production.
