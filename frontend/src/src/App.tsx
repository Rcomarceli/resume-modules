import { useState, useRef, useEffect, SyntheticEvent } from 'react'
import { ReactNode } from 'react'
import React from 'react'
import './App.css'
import './Card.css'
import './Navbar.css'
import { projectData } from './projects';
import { workExperienceData } from './workexperience';
import { educationData } from './education';

import ccnaBadge from './assets/ccna.png';
import secplusBadge from './assets/securityplus.svg';
import watchguardBadge from './assets/watchguardBadge.png';
import awsccpBadge from './assets/aws-ccp.png';
import jlptBadge from './assets/jlpt.png';

import resumeFile from './assets/resume.pdf';

import { FaBriefcase } from "react-icons/fa";
import { FaNetworkWired } from "react-icons/fa";

const linkedInUrl = "https://www.linkedin.com/in/rmarceli/";
const gitHubUrl = "https://github.com/Rcomarceli";

const resumeArticleUrl = "https://www.linkedin.com/pulse/cloud-resume-challenge-how-i-used-terraform-aws-deploy-roy-marcelino/"

const API_URL = `${import.meta.env.VITE_DOMAIN_NAME}/api`;

interface NavButtonProps {
  children?: ReactNode;
  menuMode: "" | "open";
  buttonX: "" | "x";
  onClick: React.MouseEventHandler<HTMLButtonElement>;
}
function NavButton(props: NavButtonProps) {
  return(
    <>
      <button 
      className={`nav-toggle ${props.buttonX}`}
      aria-controls="primary-navigation" 
      aria-expanded="false"
      onClick={props.onClick} >
        <span className="sr-only">Menu</span>
      </button>
      <nav id="primary-navigation" className={`${props.menuMode}`}>
        {props.children}
      </nav>
    </>
  )
}

function Navbar(props: { onClick: React.MouseEventHandler<HTMLElement> }) {
  return (
    <>
      <ul className="work-menu">
        <li>
          <a href="#projects" data-cy="nav-projects-link" onClick={props.onClick}>
            Projects
          </a>
        </li>
        <li>
          <a href="#about-me" data-cy="nav-aboutme-link" onClick={props.onClick}>
            About Me
          </a>
        </li>
        <li>
          <a href={resumeFile} 
          target="_blank" 
          rel="noopener noreferrer" 
          onClick={props.onClick}>
            Resume
          </a>
        </li>
      </ul>
      <div className="basic-contact">
        <span className="contact-me">contact me</span>
        <ul>
          <li>
            <a href="mailto:rcomarceli@gmail.com" onClick={props.onClick}>
              rcomarceli@gmail.com
            </a>
          </li>
        </ul>
      </div>
      <ul className="social-contact">
        <li>
            <a href={linkedInUrl} target="_blank" rel="noopener noreferrer">
              <svg xmlns="http://www.w3.org/2000/svg" role="img" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="feather feather-linkedin">
                <title>LinkedIn</title>
                <path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z"></path>
                <rect x="2" y="9" width="4" height="12"></rect>
                <circle cx="4" cy="4" r="2"></circle>
              </svg>
            </a>
        </li>
        <li>
            <a href={gitHubUrl} target="_blank" rel="noopener noreferrer">
            <svg xmlns="http://www.w3.org/2000/svg" role="img" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="feather feather-github"><title>GitHub</title><path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22"></path></svg>
            </a>
        </li>
      </ul>
    </>

  )
}

interface ProjectCardItemsProps {
  data: { 
    title: string, 
    shortDescription: string, 
    image: string,
    link: string,
    tooltip?: string,
  }[]
}
 
const ProjectCardItems = (props: ProjectCardItemsProps) => {
  const [selectedButtonIndex, setSelectedButtonIndex] = useState<number | undefined>();


  
  // display tooltip if link empty, prevent refresh
  function handleCardClick(event: SyntheticEvent, link: string, index: number) {
    setSelectedButtonIndex(index);
    if (link.trim() === '') event.preventDefault();
  }
  

  // clear tooltip after delay
  useEffect(() => {
    if (!selectedButtonIndex) return;

    const timer = setTimeout(() =>{
      setSelectedButtonIndex(undefined);
    }, 3500)

    return () => clearTimeout(timer);
    
  }, [selectedButtonIndex])


  return (
    <>
      {props.data.map((cardItem, index) => {

        return (
            <div key={index} className="card-container">
              <a href={cardItem.link} target="_blank" rel="noopener noreferrer" 
              onClick={(event) => handleCardClick(event, cardItem.link, index)}>

                {cardItem.tooltip && 
                  <div className={`tooltip ${selectedButtonIndex === index ? "visible" : ""}`}>
                    <p>{cardItem.tooltip}</p>
                  </div>    
                }

                <div className="card-img" style={{backgroundImage: `url(${cardItem.image})`}}></div>
                <div className="card">
                    <div className="card-title">{cardItem.title}</div>
                    <div className="card-description">{cardItem.shortDescription}</div>
                </div>
              </a>
            </div>
            )
      })}
    </>
  )
}

interface ExperienceCardItemsProps {
  data: { 
    title: string, 
    subtitle?: string
    shortDescription: string, 
  }[]
}

const ExperienceCardItems = (props: ExperienceCardItemsProps) => {
  return (
    <>
      {props.data.map((cardItem, index) => {
        return (
            <div key={index} className="experience-card-container">
              <div className="experience-card">
                  <div className="experience-card-title">{cardItem.title}</div>
                  {cardItem.subtitle && 
                    <div className="experience-card-subtitle">{cardItem.subtitle}</div>
                  }
                  <div className="experience-card-description">{cardItem.shortDescription}</div>
              </div>
            </div>
            )
      })}
    </>
  )
}

const HeroSection = () => {
  return (
    <section className="heroSection">
      <div>
        <h1 className="big-header">I'm <span>Roy</span>,</h1>
      </div>
      <div>
        <h1 className="big-header">Network & DevOps Engineer</h1>
      </div>
      <div>
        <p>
          Experienced in Enterprise networks, hybrid cloud environments, and working in the Cloud. Right now, I'm focusing on combining my networking skillset with DevOps tech to build resilient systems. 
        </p>
      </div>

      <a className="resume-link" href={resumeArticleUrl} target="_blank" rel="noreferrer">See my latest project!</a>
    </section>
  )
}

interface CertificateSectionProps {
  children?: ReactNode;
}

const CertificateSection = (props: CertificateSectionProps) => {
  return (
    <div className="cert-container">
        {props.children}
    </div>
  )
}

const ContactMe = () => {
  return (
    <div className="contactMe-container">
      <div className="contactMe-title">
        <h3>Interested in working with me?</h3>
      </div>
      <div className="contactMe-buttons">
        <a className="resume-link" href="mailto:rcomarceli@gmail.com" target="_blank" rel="noreferrer">Contact Me</a>
        <a className="resume-link" href={resumeFile} target="_blank" rel="noreferrer">Resume</a>
      </div>
    </div>
  )
}

interface Size {
  width: number | undefined;
  height: number | undefined;
}

function useWindowSize(): Size {
  // Initialize state with undefined width/height so server and client renders match
  // Learn more here: https://joshwcomeau.com/react/the-perils-of-rehydration/
  const [windowSize, setWindowSize] = useState<Size>({
    width: undefined,
    height: undefined,
  });

  useEffect(() => {
    // Handler to call on window resize
    function handleResize() {
      // Set window width/height to state
      setWindowSize({
        width: window.innerWidth,
        height: window.innerHeight,
      });
    }

    // Add event listener
    window.addEventListener("resize", handleResize);

    // Call handler right away so state gets updated with initial window size
    handleResize();

    // Remove event listener on cleanup
    return () => window.removeEventListener("resize", handleResize);
  }, []); 

  return windowSize;
}


function VisitorCounter() {
  const [visitorCount, setVisitorCount] = useState<number>();

  async function submit() {
    let res = await fetch(API_URL, {method: 'POST'});
    if (res) {
      let data = await res.json();
      setVisitorCount(data);
      return;
    }
  }

  useEffect(() => {
   submit();
  }, []);

  return(
    <div className="visitorCounter">
      <p>visitor count: {visitorCount}</p>
    </div>
  )
}


function App() {
  const [isMenuOpen, setIsMenuOpen] = useState<"" | "open">("");
  const [buttonX, setButtonX] = useState<"" | "x">("");
  const ref = useRef<HTMLElement>(null);
  const windowSize: Size = useWindowSize();





  // closes menu if user clicks outside of it
  useEffect(() => {
    const checkIfClickedOutside = (e: MouseEvent) => {
      // If the menu is open and the clicked target is not within the menu,
      // then close the menu
      if (isMenuOpen == "open" && ref.current && !ref.current.contains(e.target as Node)) {
        setIsMenuOpen('');
        setButtonX('');
      }
    }

    document.addEventListener("mousedown", checkIfClickedOutside)

    return () => {
      // Cleanup the event listener
      document.removeEventListener("mousedown", checkIfClickedOutside)
    }
  }, [isMenuOpen])



  function toggleMenuMode(event: SyntheticEvent) {
    // toggle scrolling if we are on mobile size
    // accounts for edge cases for resizing from mobile to desktop
    if (isMenuOpen == "" && windowSize.width && windowSize.width < 701) {
      document.body.classList.add('no-scroll');
    } else {
      document.body.classList.remove('no-scroll');
    }

    setIsMenuOpen(isMenuOpen == "" ? "open" : "");
    setButtonX(buttonX == ""? "x" : "");
  }

  return (
    <div className="app-core">
      <header ref={ref} className="primary-header">
        <NavButton 
        menuMode={isMenuOpen}
        buttonX={buttonX}
        onClick={toggleMenuMode}
        >
          <Navbar 
          onClick={toggleMenuMode}
          />
        </NavButton>
      </header>
      <HeroSection />
      <section id="projects">
        <h1>Projects:</h1>
        <div className="two-column">
          <ProjectCardItems data={projectData} />
        </div>
      </section>
      <section id="about-me">
        <h1>About me:</h1>
        <div className="two-column">
          <div className="column">
            <div className="resume-left">
              <FaNetworkWired />
              <h2 className="resume-heading">Work </h2>
            </div>
            <ExperienceCardItems data={workExperienceData} />
          </div>
          <div className="column">
            <div className="resume-left">
                <FaBriefcase />
                <h2 className="resume-heading">
                Education </h2>
            </div>  
            <ExperienceCardItems data={educationData} />
          </div>
        </div>
      </section>
      <section id="certifications">
        <h1>Certifications:</h1>
        <CertificateSection>
          <img className="autofit-image" src={ccnaBadge} alt="badge"/>
          <img className="autofit-image" src={jlptBadge} alt="badge"/>
          <img className="autofit-image" src={watchguardBadge} alt="badge"/>
          <img className="autofit-image" src={secplusBadge} alt="badge"/>
          <img className="autofit-image" src={awsccpBadge} alt="badge"/>
        </CertificateSection>
      </section>

      <section className="contactMe">
        <ContactMe />
      </section>
      <VisitorCounter />

    </div>
  )
}

export default App


// source: https://dev.to/collegewap/how-to-detect-click-outside-in-a-react-component-2b6k
// https://codingbeautydev.com/blog/react-get-window-width-height/