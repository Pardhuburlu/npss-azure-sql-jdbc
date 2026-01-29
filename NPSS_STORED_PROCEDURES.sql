-- Q1: Insert a new visitor and enroll into a Program
CREATE OR ALTER PROCEDURE dbo.InsertVisitorAndEnroll
  @IDNumber        varchar(30),
  @FirstName       varchar(50),
  @MiddleName      varchar(50) = NULL,
  @LastName        varchar(50),
  @DOB             date,
  @Gender          varchar(10),
  @Street          varchar(80),
  @City            varchar(60),
  @State           varchar(30),
  @PostalCode      varchar(20),
  @IsSubscribed    bit,
  @ParkName        varchar(80),
  @ProgramName     varchar(100),
  @VisitDate       date,
  @Accessibility   varchar(120) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT EXISTS (SELECT 1 FROM Person WHERE IDNumber=@IDNumber)
    INSERT INTO Person(IDNumber, FirstName, LastName, MiddleName, DOB, Gender, Street, City, State, PostalCode, IsSubscribed)
    VALUES (@IDNumber, @FirstName, @LastName, @MiddleName, @DOB, @Gender, @Street, @City, @State, @PostalCode, @IsSubscribed);

  IF NOT EXISTS (SELECT 1 FROM Visitor WHERE IDNumber=@IDNumber)
    INSERT INTO Visitor(IDNumber) VALUES (@IDNumber);

  IF NOT EXISTS (
      SELECT 1 FROM Enrollment
      WHERE ParkName=@ParkName AND ProgramName=@ProgramName AND IDNumber=@IDNumber AND VisitDate=@VisitDate
  )
    INSERT INTO Enrollment(ParkName, ProgramName, IDNumber, VisitDate, Accessibility)
    VALUES (@ParkName, @ProgramName, @IDNumber, @VisitDate, @Accessibility);
END
GO


-- Q2: Insert a new ranger and assign to a team
CREATE OR ALTER PROCEDURE dbo.InsertRangerAndAssign
  @IDNumber        varchar(30),
  @FirstName       varchar(50),
  @MiddleName      varchar(50) = NULL,
  @LastName        varchar(50),
  @DOB             date,
  @Gender          varchar(10),
  @Street          varchar(80),
  @City            varchar(60),
  @State           varchar(30),
  @PostalCode      varchar(20),
  @IsSubscribed    bit,
  @StartDate       date,
  @Status          varchar(10),
  @TeamID          varchar(30)
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT EXISTS (SELECT 1 FROM Person WHERE IDNumber=@IDNumber)
    INSERT INTO Person(IDNumber, FirstName, LastName, MiddleName, DOB, Gender, Street, City, State, PostalCode, IsSubscribed)
    VALUES (@IDNumber, @FirstName, @LastName, @MiddleName, @DOB, @Gender, @Street, @City, @State, @PostalCode, @IsSubscribed);

  IF NOT EXISTS (SELECT 1 FROM Ranger WHERE IDNumber=@IDNumber)
    INSERT INTO Ranger(IDNumber, StartDate, Status) VALUES (@IDNumber, @StartDate, @Status);
  ELSE
    UPDATE Ranger SET StartDate=@StartDate, Status=@Status WHERE IDNumber=@IDNumber;

  IF NOT EXISTS (SELECT 1 FROM Includes WHERE IDNumber=@IDNumber)
    INSERT INTO Includes(TeamID, IDNumber) VALUES (@TeamID, @IDNumber);
  ELSE
    UPDATE Includes SET TeamID=@TeamID WHERE IDNumber=@IDNumber;
END
GO


-- Q3: Insert a new team and set its leaderID 
CREATE OR ALTER PROCEDURE dbo.InsertTeamAndLeader
  @TeamID        varchar(30),
  @FocusArea     varchar(80),
  @FormationDate date,
  @LeaderID      varchar(30)  
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT EXISTS (SELECT 1 FROM RangerTeam WHERE TeamID=@TeamID)
    INSERT INTO RangerTeam(TeamID, FocusArea, FormationDate) VALUES (@TeamID, @FocusArea, @FormationDate);
  ELSE
    UPDATE RangerTeam SET FocusArea=@FocusArea, FormationDate=@FormationDate WHERE TeamID=@TeamID;

  IF NOT EXISTS (SELECT 1 FROM Ranger WHERE IDNumber=@LeaderID)
    INSERT INTO Ranger(IDNumber, StartDate, Status) VALUES (@LeaderID, @FormationDate, 'active');

  IF NOT EXISTS (SELECT 1 FROM Includes WHERE IDNumber=@LeaderID)
    INSERT INTO Includes(TeamID, IDNumber) VALUES (@TeamID, @LeaderID);
  ELSE
    UPDATE Includes SET TeamID=@TeamID WHERE IDNumber=@LeaderID;

  IF NOT EXISTS (SELECT 1 FROM TeamLeader WHERE TeamID=@TeamID)
    INSERT INTO TeamLeader(TeamID, IDNumber) VALUES (@TeamID, @LeaderID);
  ELSE
    UPDATE TeamLeader SET IDNumber=@LeaderID WHERE TeamID=@TeamID;
END
GO

-- Q4: Insert a donation (also check whether CHECK or CARD)
CREATE OR ALTER PROCEDURE dbo.InsertDonation
  @IDNumber     varchar(30),
  @DonationDate date,
  @Amount       decimal(12,2),
  @CampaignName varchar(100) = NULL,
  @PaymentType  varchar(10),        -- 'CHECK' or 'CARD'
  @CheckNumber  varchar(30) = NULL, -- for CHECK
  @CardType     varchar(30) = NULL, -- for CARD
  @LastFour     varchar(4)  = NULL, -- for CARD
  @Expiration   date        = NULL  -- for CARD
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT EXISTS (SELECT 1 FROM Donation WHERE IDNumber=@IDNumber AND DonationDate=@DonationDate)
    INSERT INTO Donation(IDNumber, DonationDate, Amount, CampaignName)
    VALUES (@IDNumber, @DonationDate, @Amount, @CampaignName);
  ELSE
    UPDATE Donation SET Amount=@Amount, CampaignName=@CampaignName
    WHERE IDNumber=@IDNumber AND DonationDate=@DonationDate;

  IF UPPER(@PaymentType)='CHECK'
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM CheckDonation WHERE IDNumber=@IDNumber AND DonationDate=@DonationDate)
      INSERT INTO CheckDonation(IDNumber, DonationDate, CheckNumber)
      VALUES (@IDNumber, @DonationDate, @CheckNumber);
    ELSE
      UPDATE CheckDonation SET CheckNumber=@CheckNumber
      WHERE IDNumber=@IDNumber AND DonationDate=@DonationDate;
  END
  ELSE
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM CardDonation WHERE IDNumber=@IDNumber AND DonationDate=@DonationDate)
      INSERT INTO CardDonation(IDNumber, DonationDate, CardType, LastFour, Expiration)
      VALUES (@IDNumber, @DonationDate, @CardType, @LastFour, @Expiration);
    ELSE
      UPDATE CardDonation SET CardType=@CardType, LastFour=@LastFour, Expiration=@Expiration
      WHERE IDNumber=@IDNumber AND DonationDate=@DonationDate;
  END
END
GO


-- Q5: Insert a new researcher into the database and associate them with one or more ranger teams (1/year).
CREATE OR ALTER PROCEDURE dbo.InsertResearcherAndAssign
  @IDNumber      varchar(30),   -- Person.IDNumber of the researcher
  @FirstName     varchar(50),
  @MiddleName    varchar(50) = NULL,
  @LastName      varchar(50),
  @DOB           date,
  @Gender        varchar(10),
  @Street        varchar(80),
  @City          varchar(60),
  @State         varchar(30),
  @PostalCode    varchar(20),
  @IsSubscribed  bit,
  @ResearchField varchar(80),
  @HireDate      date,
  @Salary        decimal(12,2),
  @TeamID        varchar(30)
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT EXISTS (SELECT 1 FROM Person WHERE IDNumber=@IDNumber)
    INSERT INTO Person(IDNumber, FirstName, LastName, MiddleName, DOB, Gender, Street, City, State, PostalCode, IsSubscribed)
    VALUES (@IDNumber, @FirstName, @LastName, @MiddleName, @DOB, @Gender, @Street, @City, @State, @PostalCode, @IsSubscribed);

  IF NOT EXISTS (SELECT 1 FROM Researcher WHERE IDNumber=@IDNumber)
    INSERT INTO Researcher(IDNumber, ResearchField, HireDate, Salary)
    VALUES (@IDNumber, @ResearchField, @HireDate, @Salary);
  ELSE
    UPDATE Researcher SET ResearchField=@ResearchField, HireDate=@HireDate, Salary=@Salary
    WHERE IDNumber=@IDNumber;

  IF EXISTS (SELECT 1 FROM Oversee WHERE TeamID=@TeamID)
    DELETE FROM Oversee WHERE TeamID=@TeamID;

  INSERT INTO Oversee(TeamID, IDNumber) VALUES (@TeamID, @IDNumber);
END
GO


-- Q6: Insert a report submitted by a ranger team to a researcher (10/month)
CREATE OR ALTER PROCEDURE dbo.InsertTeamReport
  @TeamID       varchar(30),
  @IDNumber     varchar(30),  
  @ReportDate   date,
  @Summary      varchar(1000)
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO Report(TeamID, IDNumber, ReportDate, SummaryOfActivities)
  VALUES (@TeamID, @IDNumber, @ReportDate, @Summary);
END
GO


-- Q7: Insert a new park program into the database for a specific park (2/month)
CREATE OR ALTER PROCEDURE dbo.InsertProgram
  @ParkName    varchar(80),
  @ProgramName varchar(100),
  @Type        varchar(40),
  @StartDate   date,
  @Duration    int
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT EXISTS (SELECT 1 FROM Program WHERE ParkName=@ParkName AND ProgramName=@ProgramName)
    INSERT INTO Program(ParkName, ProgramName, Type, StartDate, Duration)
    VALUES (@ParkName, @ProgramName, @Type, @StartDate, @Duration);
  ELSE
    UPDATE Program SET Type=@Type, StartDate=@StartDate, Duration=@Duration
    WHERE ParkName=@ParkName AND ProgramName=@ProgramName;
END
GO


-- Q8: Retrieve the names and contact information of all emergency contacts for a specific person (2/week).
CREATE OR ALTER PROCEDURE dbo.GetEmergencyContacts
  @IDNumber varchar(30)
AS
BEGIN
  SET NOCOUNT ON;
  SELECT ec.ContactName, ec.Relationship, ec.PhoneNumber
  FROM HasEmergencyContact h
  JOIN EmergencyContact ec
    ON ec.ContactName = h.ContactName AND ec.PhoneNumber = h.PhoneNumber
  WHERE h.IDNumber = @IDNumber
  ORDER BY ec.ContactName;
END
GO


-- Q9: Retrieve the list of visitors enrolled in a specific park program, including their accessibility needs (2/week).
CREATE OR ALTER PROCEDURE dbo.GetVisitorsInProgram
  @ParkName    varchar(80),
  @ProgramName varchar(100)
AS
BEGIN
  SET NOCOUNT ON;
  SELECT p.IDNumber, p.FirstName, p.LastName, e.VisitDate, e.Accessibility
  FROM Enrollment e
  JOIN Person p ON p.IDNumber = e.IDNumber
  WHERE e.ParkName=@ParkName AND e.ProgramName=@ProgramName
  ORDER BY e.VisitDate, p.LastName, p.FirstName;
END
GO


-- Q10: Retrieve all park programs for a specific park that started after a given date (1/month).
CREATE OR ALTER PROCEDURE dbo.GetProgramsInParkAfter
  @ParkName  varchar(80),
  @AfterDate date
AS
BEGIN
  SET NOCOUNT ON;
  SELECT ParkName, ProgramName, Type, StartDate, Duration
  FROM Program
  WHERE ParkName=@ParkName AND StartDate > @AfterDate
  ORDER BY StartDate, ProgramName;
END
GO


-- Q11: Retrieve total and average donation amount in a month from all anonymous donors, sorted in desecding order (1/month).
CREATE OR ALTER PROCEDURE dbo.GetMonthlyAnonDonationAgg
  @Year  int,
  @Month int
AS
BEGIN
  SET NOCOUNT ON;
  SELECT d.IDNumber,
         p.FirstName,
         p.LastName,
         SUM(n.Amount) AS TotalAmount,
         AVG(n.Amount) AS AvgAmount,
         COUNT(*)      AS Donations
  FROM Donor d
  JOIN Person p ON p.IDNumber = d.IDNumber
  JOIN Donation n ON n.IDNumber = d.IDNumber
  WHERE d.AnonymityPreference = 1
    AND YEAR(n.DonationDate) = @Year
    AND MONTH(n.DonationDate) = @Month
  GROUP BY d.IDNumber, p.FirstName, p.LastName
  ORDER BY TotalAmount DESC;
END
GO


-- Q12: Retrieve the list of rangers in a team, including certifications, years of service and role (leader/member) (4/year).
CREATE OR ALTER PROCEDURE dbo.GetTeamRangersWithDetails
  @TeamID varchar(30)
AS
BEGIN
  SET NOCOUNT ON;
  SELECT r.IDNumber,
         p.FirstName,
         p.LastName,
         r.YearsOfService,
         ISNULL(rc.Certification, '(none)') AS CertificationName,
         CASE WHEN tl.TeamID IS NULL THEN 'member' ELSE 'leader' END AS RoleInTeam
  FROM Includes i
  JOIN Ranger r  ON r.IDNumber = i.IDNumber
  JOIN Person p  ON p.IDNumber = r.IDNumber
  LEFT JOIN RangerCertification rc ON rc.IDNumber = r.IDNumber
  LEFT JOIN TeamLeader tl ON tl.TeamID = i.TeamID AND tl.IDNumber = i.IDNumber
  WHERE i.TeamID = @TeamID
  ORDER BY RoleInTeam DESC, p.LastName, p.FirstName, rc.Certification;
END
GO


-- Q13: Retrieve names, IDs, contact info, and newsletter subscription of all individuals (1/week).
CREATE OR ALTER PROCEDURE dbo.GetAllIndividualsMailing
AS
BEGIN
  SET NOCOUNT ON;
  SELECT p.IDNumber, p.FirstName, p.LastName,
         p.Street, p.City, p.State, p.PostalCode,
         (SELECT STRING_AGG(pe.Email, ';') FROM PersonEmail pe WHERE pe.IDNumber = p.IDNumber)  AS Emails,
         (SELECT STRING_AGG(pph.PhoneNumber, ';') FROM PersonPhone pph WHERE pph.IDNumber = p.IDNumber) AS Phones,
         p.IsSubscribed
  FROM Person p
  ORDER BY p.LastName, p.FirstName;
END
GO


-- Q14: Update salary of researchers overseeing more than one ranger team by 3% (1/year).
CREATE OR ALTER PROCEDURE dbo.BumpResearcherSalaryForMultiTeams
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE r
    SET r.Salary = CAST(r.Salary * 1.03 AS decimal(12,2))
  FROM Researcher r
  WHERE r.IDNumber IN (
    SELECT o.IDNumber
    FROM Oversee o
    GROUP BY o.IDNumber
    HAVING COUNT(*) > 1
  );
END
GO


-- Q15: Delete visitors with no enrollments and no active (non-expired) pass (2/year).
CREATE OR ALTER PROCEDURE dbo.DeleteIdleVisitors
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM Visitor
  WHERE IDNumber NOT IN (SELECT IDNumber FROM Enrollment)
    AND NOT EXISTS (
      SELECT 1
      FROM HoldsPass hp
      JOIN ParkPass pp ON pp.PassID = hp.PassID
      WHERE hp.IDNumber = Visitor.IDNumber
        AND pp.ExpiryDate >= CAST(GETDATE() AS date)
    );
END
GO
