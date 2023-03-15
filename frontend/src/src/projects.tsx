import resumeImage from './assets/resumeImage.png';
import pythonImage from './assets/pythonImage.png';
import vbscriptImage from './assets/vbscriptImage.png';
import discordImage from './assets/discordImage.png';

export const projectData = [  
    {
        "title": "Serverless Resume🥇",
        "shortDescription": "Serverless architecture via AWS and Cloudflare, deployed via Terraform and Github actions.",
        "image": resumeImage,
        "link": "https://www.linkedin.com/pulse/cloud-resume-challenge-how-i-used-terraform-aws-deploy-roy-marcelino/",
    },
    {
        "title": "ADTRAN Script",
        "shortDescription": "Concurrently SSHs into site switches, grabs metrics, outputs spreadsheets and uploads configs to Onedrive",
        "image": pythonImage,
        "link": "",
        "tooltip": "Source unavailable since this was for a employer. More project details in my resume!"
    },
    {
        "title": "Circuit Metrics Script",
        "shortDescription": "Queries network devices for circuit utilization, aggregates data into a user-readable table",
        "image": vbscriptImage,
        "link": "https://github.com/Rcomarceli/UtilTable",
    },
    {
        "title": "Discord Bot",
        "shortDescription": "Automated Bot that stores screenplays in SQL and allows users to fetch screenplay URLs",
        "image": discordImage,
        "link": "https://github.com/Rcomarceli/Actor",
    },
];