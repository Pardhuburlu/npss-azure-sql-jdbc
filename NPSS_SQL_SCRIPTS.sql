CREATE TABLE Person (
  IDNumber varchar(30) NOT NULL,
  FirstName varchar(50) NOT NULL,
  LastName varchar(50) NOT NULL,
  MiddleName varchar(50) NULL,
  DOB date NOT NULL,
  Gender varchar(10) NOT NULL,
  Street varchar(80) NOT NULL,
  City varchar(60) NOT NULL,
  State varchar(30) NOT NULL,
  PostalCode varchar(20) NOT NULL,
  IsSubscribed bit NOT NULL DEFAULT(0),
  Age AS (DATEDIFF(year, DOB, GETDATE())
    - CASE WHEN DATEADD(year, DATEDIFF(year, DOB, GETDATE()), DOB) > CAST(GETDATE() AS date) THEN 1 ELSE 0 END),
  CONSTRAINT PK_Person PRIMARY KEY CLUSTERED (IDNumber)
);

CREATE INDEX INDX_Person_Name ON Person(LastName, FirstName);

CREATE TABLE PersonPhone (
  IDNumber varchar(30) NOT NULL,
  PhoneNumber varchar(20) NOT NULL,
  CONSTRAINT PK_PersonPhone PRIMARY KEY CLUSTERED (IDNumber, PhoneNumber),
  CONSTRAINT FK_PersonPhone_Person FOREIGN KEY (IDNumber) REFERENCES Person(IDNumber)
);

CREATE TABLE PersonEmail (
  IDNumber varchar(30) NOT NULL,
  Email varchar(100) NOT NULL,
  CONSTRAINT PK_PersonEmail PRIMARY KEY CLUSTERED (IDNumber, Email),
  CONSTRAINT FK_PersonEmail_Person FOREIGN KEY (IDNumber) REFERENCES Person(IDNumber)
);

CREATE TABLE Visitor (
  IDNumber varchar(30) NOT NULL,
  CONSTRAINT PK_Visitor PRIMARY KEY CLUSTERED (IDNumber),
  CONSTRAINT FK_Visitor_Person FOREIGN KEY (IDNumber) REFERENCES Person(IDNumber)
);

CREATE TABLE Ranger (
  IDNumber varchar(30) NOT NULL,
  StartDate date NOT NULL,
  Status varchar(10) NOT NULL CHECK (Status IN ('active','inactive')),
  YearsOfService AS (DATEDIFF(year, StartDate, GETDATE())
    - CASE WHEN DATEADD(year, DATEDIFF(year, StartDate, GETDATE()), StartDate) > CAST(GETDATE() AS date) THEN 1 ELSE 0 END),
  CONSTRAINT PK_Ranger PRIMARY KEY CLUSTERED (IDNumber),
  CONSTRAINT FK_Ranger_Person FOREIGN KEY (IDNumber) REFERENCES Person(IDNumber)
);

CREATE TABLE RangerCertification (
  IDNumber varchar(30) NOT NULL,
  Certification varchar(80) NOT NULL,
  CONSTRAINT PK_RangerCertification PRIMARY KEY CLUSTERED (IDNumber, Certification),
  CONSTRAINT FK_RangerCertification_Ranger FOREIGN KEY (IDNumber) REFERENCES Ranger(IDNumber)
);

CREATE TABLE Researcher (
  IDNumber varchar(30) NOT NULL,
  ResearchField varchar(80) NOT NULL,
  HireDate date NOT NULL,
  Salary decimal(12,2) NOT NULL CHECK (Salary >= 0),
  CONSTRAINT PK_Researcher PRIMARY KEY CLUSTERED (IDNumber),
  CONSTRAINT FK_Researcher_Person FOREIGN KEY (IDNumber) REFERENCES Person(IDNumber)
);

CREATE TABLE Donor (
  IDNumber varchar(30) NOT NULL,
  AnonymityPreference bit NOT NULL DEFAULT(0),
  CONSTRAINT PK_Donor PRIMARY KEY CLUSTERED (IDNumber),
  CONSTRAINT FK_Donor_Person FOREIGN KEY (IDNumber) REFERENCES Person(IDNumber)
);

CREATE TABLE RangerTeam (
  TeamID varchar(30) NOT NULL,
  FocusArea varchar(80) NOT NULL,
  FormationDate date NOT NULL,
  CONSTRAINT PK_RangerTeam PRIMARY KEY CLUSTERED (TeamID)
);

CREATE TABLE Oversee (
  TeamID varchar(30) NOT NULL,
  IDNumber varchar(30) NOT NULL,
  CONSTRAINT PK_Oversee PRIMARY KEY CLUSTERED (TeamID, IDNumber),
  CONSTRAINT UQ_Oversee_OnePerTeam UNIQUE (TeamID),
  CONSTRAINT FK_Oversee_Team FOREIGN KEY (TeamID) REFERENCES RangerTeam(TeamID),
  CONSTRAINT FK_Oversee_Person FOREIGN KEY (IDNumber) REFERENCES Person(IDNumber)
);

CREATE TABLE Includes (
  TeamID varchar(30) NOT NULL,
  IDNumber varchar(30) NOT NULL,
  CONSTRAINT PK_Includes PRIMARY KEY CLUSTERED (TeamID, IDNumber),
  CONSTRAINT UQ_Includes_OneTeamPerRanger UNIQUE (IDNumber),
  CONSTRAINT FK_Includes_Team FOREIGN KEY (TeamID) REFERENCES RangerTeam(TeamID),
  CONSTRAINT FK_Includes_Ranger FOREIGN KEY (IDNumber) REFERENCES Ranger(IDNumber)
);

CREATE TABLE TeamLeader (
  TeamID varchar(30) NOT NULL,
  IDNumber varchar(30) NOT NULL,
  CONSTRAINT PK_TeamLeader PRIMARY KEY CLUSTERED (TeamID),
  CONSTRAINT FK_TeamLeader_Includes FOREIGN KEY (TeamID, IDNumber) REFERENCES Includes(TeamID, IDNumber)
);

CREATE TABLE NationalPark (
  ParkName varchar(80) NOT NULL,
  Street varchar(80) NOT NULL,
  City varchar(60) NOT NULL,
  State varchar(30) NOT NULL,
  PostalCode varchar(20) NOT NULL,
  EstablishedDate date NOT NULL,
  VisitorCapacity int NOT NULL,
  CONSTRAINT PK_NationalPark PRIMARY KEY CLUSTERED (ParkName)
);

CREATE TABLE Program (
  ParkName varchar(80) NOT NULL,
  ProgramName varchar(100) NOT NULL,
  Type varchar(40) NOT NULL,
  StartDate date NOT NULL,
  Duration int NOT NULL,
  CONSTRAINT PK_Program PRIMARY KEY CLUSTERED (ParkName, ProgramName),
  CONSTRAINT FK_Program_Park FOREIGN KEY (ParkName) REFERENCES NationalPark(ParkName)
);

CREATE INDEX INDX_Program_Park_StartDate ON Program(ParkName, StartDate);

CREATE TABLE Enrollment (
  ParkName varchar(80) NOT NULL,
  ProgramName varchar(100) NOT NULL,
  IDNumber varchar(30) NOT NULL,
  VisitDate date NOT NULL,
  Accessibility varchar(120) NULL,
  CONSTRAINT PK_Enrollment PRIMARY KEY CLUSTERED (ParkName, ProgramName, VisitDate, IDNumber),
  CONSTRAINT FK_Enrollment_Program FOREIGN KEY (ParkName, ProgramName) REFERENCES Program(ParkName, ProgramName),
  CONSTRAINT FK_Enrollment_Visitor FOREIGN KEY (IDNumber) REFERENCES Visitor(IDNumber)
);

CREATE INDEX INDX_Enrollment_Visitor ON Enrollment(IDNumber);

CREATE TABLE ParkPass (
  PassID varchar(30) NOT NULL,
  Type varchar(40) NOT NULL,
  ExpiryDate date NOT NULL,
  CONSTRAINT PK_ParkPass PRIMARY KEY CLUSTERED (PassID)
);

CREATE INDEX INDX_ParkPass_Expiry ON ParkPass(ExpiryDate);

CREATE TABLE HoldsPass (
  IDNumber varchar(30) NOT NULL,
  PassID varchar(30) NOT NULL,
  CONSTRAINT PK_HoldsPass PRIMARY KEY CLUSTERED (IDNumber, PassID),
  CONSTRAINT FK_HoldsPass_Person FOREIGN KEY (IDNumber) REFERENCES Person(IDNumber),
  CONSTRAINT FK_HoldsPass_Pass FOREIGN KEY (PassID) REFERENCES ParkPass(PassID)
);

CREATE INDEX INDX_HoldsPass_ID ON HoldsPass(IDNumber);

CREATE TABLE EmergencyContact (
  ContactName varchar(80) NOT NULL,
  Relationship varchar(40) NOT NULL,
  PhoneNumber varchar(20) NOT NULL,
  CONSTRAINT PK_EmergencyContact PRIMARY KEY CLUSTERED (ContactName, PhoneNumber)
);

CREATE TABLE HasEmergencyContact (
  IDNumber varchar(30) NOT NULL,
  ContactName varchar(80) NOT NULL,
  PhoneNumber varchar(20) NOT NULL,
  CONSTRAINT PK_HasEmergencyContact PRIMARY KEY CLUSTERED (IDNumber, ContactName, PhoneNumber),
  CONSTRAINT FK_HasEmergencyContact_Person FOREIGN KEY (IDNumber) REFERENCES Person(IDNumber),
  CONSTRAINT FK_HasEmergencyContact_Contact FOREIGN KEY (ContactName, PhoneNumber) REFERENCES EmergencyContact(ContactName, PhoneNumber)
);

CREATE TABLE ConservationProject (
  ProjectID varchar(30) NOT NULL,
  Name varchar(120) NOT NULL,
  StartDate date NOT NULL,
  Budget decimal(14,2) NOT NULL CHECK (Budget >= 0),
  CONSTRAINT PK_ConservationProject PRIMARY KEY CLUSTERED (ProjectID)
);

CREATE TABLE Hosts (
  ParkName varchar(80) NOT NULL,
  ProjectID varchar(30) NOT NULL,
  CONSTRAINT PK_Hosts PRIMARY KEY CLUSTERED (ParkName, ProjectID),
  CONSTRAINT FK_Hosts_Park FOREIGN KEY (ParkName) REFERENCES NationalPark(ParkName),
  CONSTRAINT FK_Hosts_Project FOREIGN KEY (ProjectID) REFERENCES ConservationProject(ProjectID)
);

CREATE TABLE Operates (
  TeamID varchar(30) NOT NULL,
  ParkName varchar(80) NOT NULL,
  CONSTRAINT PK_Operates PRIMARY KEY CLUSTERED (TeamID, ParkName),
  CONSTRAINT FK_Operates_Team FOREIGN KEY (TeamID) REFERENCES RangerTeam(TeamID),
  CONSTRAINT FK_Operates_Park FOREIGN KEY (ParkName) REFERENCES NationalPark(ParkName)
);

CREATE INDEX INDX_Operates_Park ON Operates(ParkName);

CREATE TABLE Report (
  TeamID varchar(30) NOT NULL,
  IDNumber varchar(30) NOT NULL,
  ReportDate date NOT NULL,
  SummaryOfActivities varchar(1000) NOT NULL,
  CONSTRAINT PK_Report PRIMARY KEY CLUSTERED (TeamID, ReportDate),
  CONSTRAINT FK_Report_Team FOREIGN KEY (TeamID) REFERENCES RangerTeam(TeamID),
  CONSTRAINT FK_Report_Oversee FOREIGN KEY (TeamID, IDNumber) REFERENCES Oversee(TeamID, IDNumber)
);

CREATE INDEX INDX_Report_IDNumber ON Report(IDNumber);

CREATE TABLE Donation (
  IDNumber varchar(30) NOT NULL,
  DonationDate date NOT NULL,
  Amount decimal(12,2) NOT NULL,
  CampaignName varchar(100) NULL,
  CONSTRAINT PK_Donation PRIMARY KEY CLUSTERED (IDNumber, DonationDate),
  CONSTRAINT FK_Donation_Donor FOREIGN KEY (IDNumber) REFERENCES Donor(IDNumber)
);

CREATE INDEX INDX_Donation_Date ON Donation(DonationDate);

CREATE TABLE CheckDonation (
  IDNumber varchar(30) NOT NULL,
  DonationDate date NOT NULL,
  CheckNumber varchar(30) NOT NULL,
  CONSTRAINT PK_CheckDonation PRIMARY KEY CLUSTERED (IDNumber, DonationDate),
  CONSTRAINT FK_CheckDonation_Donation FOREIGN KEY (IDNumber, DonationDate) REFERENCES Donation(IDNumber, DonationDate)
);

CREATE TABLE CardDonation (
  IDNumber varchar(30) NOT NULL,
  DonationDate date NOT NULL,
  CardType varchar(30) NOT NULL,
  LastFour varchar(4) NOT NULL,
  Expiration date NOT NULL,
  CONSTRAINT PK_CardDonation PRIMARY KEY CLUSTERED (IDNumber, DonationDate),
  CONSTRAINT FK_CardDonation_Donation FOREIGN KEY (IDNumber, DonationDate) REFERENCES Donation(IDNumber, DonationDate)
);

CREATE TABLE Mentorship (
  MentorID varchar(30) NOT NULL,
  MenteeID varchar(30) NOT NULL,
  StartDate date NOT NULL,
  CONSTRAINT PK_Mentorship PRIMARY KEY CLUSTERED (MentorID, MenteeID),
  CONSTRAINT UQ_Mentorship_UniqueMentor UNIQUE (MentorID),
  CONSTRAINT UQ_Mentorship_UniqueMentee UNIQUE (MenteeID),
  CONSTRAINT FK_Mentorship_Mentor FOREIGN KEY (MentorID) REFERENCES Ranger(IDNumber),
  CONSTRAINT FK_Mentorship_Mentee FOREIGN KEY (MenteeID) REFERENCES Ranger(IDNumber),
  CONSTRAINT CK_Mentorship_NoSelf CHECK (MentorID <> MenteeID)
);
