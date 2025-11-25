export const skillsData = {
  departments: [
    {
      name: "Computer Science",
      skills: [
        "Python Programming", "Java Programming", "C++ Programming", "C Programming",
        "JavaScript", "TypeScript", "Go Programming", "Rust Programming", "R Programming",
        "PHP Development", "Laravel Framework", "React.js", "Next.js", "Vue.js", "Angular.js",
        "Node.js", "Express.js", "Django", "Flask", "Spring Boot", "REST API Development",
        "GraphQL API Development", "Microservices Architecture", "Software Architecture Design",
        "Database Design", "MySQL", "PostgreSQL", "MongoDB", "Cassandra", "Redis", "SQLite",
        "Cloud Computing (AWS)", "Cloud Computing (Azure)", "Cloud Computing (GCP)",
        "Cloud Security", "Docker", "Kubernetes", "Terraform", "CI/CD Pipelines",
        "Git & GitHub", "Linux Administration", "Cybersecurity", "Penetration Testing",
        "Ethical Hacking", "Machine Learning", "Deep Learning", "TensorFlow", "PyTorch",
        "NLP", "Computer Vision", "Big Data (Hadoop)", "Apache Spark", "Data Engineering",
        "Business Intelligence", "Tableau", "Power BI", "Mobile App Development (Flutter)",
        "Android Development", "iOS Development", "Blockchain Development", "AR/VR Development"
      ]
    },
    {
      name: "Management Sciences",
      skills: [
        "Business Strategy Development", "Financial Accounting", "Cost Accounting",
        "Corporate Finance", "Taxation Basics", "Financial Modeling", "Investment Analysis",
        "Portfolio Management", "Risk Management", "Microeconomics", "Macroeconomics",
        "Business Analytics", "Excel Advanced", "Power BI", "Data Interpretation",
        "Market Research", "Consumer Behavior Analysis", "Marketing Strategy",
        "Brand Management", "Sales Strategy", "CRM Tools", "Supply Chain Management",
        "Operations Management", "Inventory Management", "Procurement", "Logistics Management",
        "Lean Management", "Six Sigma Basics", "Project Management", "Agile Management",
        "Scrum Framework", "MS Project", "Human Resource Management", "Recruitment & Selection",
        "Performance Evaluation", "Business Communication", "Negotiation Skills",
        "Digital Marketing", "SEO", "Google Ads", "Facebook Ads", "Business Planning",
        "Content Marketing", "Public Relations"
      ]
    },
    {
      name: "Electrical & Computer Engineering",
      skills: [
        "Circuit Analysis", "Analog Circuit Design", "Digital Circuit Design",
        "Microprocessors", "Microcontrollers (PIC, AVR, STM32)", "Embedded C",
        "Arduino Development", "Raspberry Pi Projects", "FPGA Design", "Verilog Programming",
        "VHDL Programming", "Signal Processing", "Digital Signal Processing",
        "Power Systems Analysis", "Power Electronics", "Control Systems Engineering",
        "Automation Engineering", "SCADA Systems", "PLC Programming", "Instrumentation",
        "IoT System Design", "Wireless Sensor Networks", "Communication Systems",
        "RF Engineering", "Antenna Design", "Renewable Energy Systems", "Solar System Design",
        "Wind Energy Systems", "Electric Machines", "PCB Design (Altium)", "PCB Design (Proteus)",
        "MATLAB", "Simulink", "Multisim", "LabVIEW", "Battery Management Systems",
        "Electric Vehicle Systems", "Smart Grid Technologies", "High Voltage Engineering"
      ]
    },
    {
      name: "Mechanical Engineering",
      skills: [
        "Mechanical Design", "AutoCAD", "SolidWorks", "CATIA", "Fusion 360", "PTC Creo",
        "3D Modeling", "Finite Element Analysis (FEA)", "ANSYS Workbench", "Thermodynamics",
        "Heat Transfer", "Fluid Mechanics", "CFD Analysis", "CNC Programming",
        "CAM Systems", "Machine Design", "Material Selection", "Failure Analysis",
        "Vibrations Analysis", "Dynamics of Machines", "Mechatronics", "Robotics Basics",
        "Automotive Mechanics", "HVAC System Design", "Boiler Systems", "Piping Design",
        "Welding Technologies", "Industrial Safety", "Maintenance Engineering",
        "Quality Control", "Reliability Engineering", "3D Printing", "Hydraulics", 
        "Pneumatics", "Energy Systems", "Power Plant Operations"
      ]
    },
    {
      name: "Civil Engineering",
      skills: [
        "Structural Analysis", "Reinforced Concrete Design", "Steel Structure Design",
        "AutoCAD Drafting", "Revit Architecture", "ETABS Modeling", "SAFE Analysis",
        "STAAD.Pro", "Soil Mechanics", "Foundation Engineering", "Construction Management",
        "Project Scheduling", "Primavera P6", "MS Project", "Quantity Surveying",
        "Cost Estimation", "Highway Engineering", "Transportation Engineering",
        "Hydraulics", "Water Supply Design", "Sewerage Design", "GIS Mapping", "ArcGIS",
        "Geotechnical Analysis", "Urban Planning", "Concrete Technology", 
        "Earthquake Engineering", "Site Supervision", "Contract Management"
      ]
    }
  ],
  softSkills: [
    "Verbal Communication", "Written Communication", "Active Listening",
    "Public Speaking", "Presentation Skills", "Negotiation", "Persuasion",
    "Storytelling", "Email Etiquette", "Professional Communication",
    "Team Leadership", "Decision Making", "Conflict Management", "Delegation",
    "Strategic Thinking", "Mentoring", "People Management", "Change Management",
    "Teamwork", "Collaboration", "Empathy", "Relationship Building",
    "Cultural Awareness", "Emotional Intelligence", "Networking",
    "Analytical Thinking", "Logical Reasoning", "Critical Thinking",
    "Creative Problem Solving", "Brainstorming", "Root Cause Analysis",
    "Time Management", "Prioritization", "Planning & Scheduling",
    "Attention to Detail", "Task Management", "Multitasking",
    "Stress Management",
    "Creative Thinking", "Design Thinking", "Idea Generation",
    "Problem Ideation", "User-Focused Thinking"
  ]
};

// Flatten and deduplicate all skills for the search dropdown
export const allSkillsList = [
  ...new Set([
    ...skillsData.departments.flatMap(d => d.skills),
    ...skillsData.softSkills
  ])
].sort();