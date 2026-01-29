import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.Scanner;

import java.sql.Date;


public class Task5 {
	
	// ---- EDIT THESE ----
	// these are my cloud sql details… i keep it simple here, not doing fancy config
	private static final String HOSTNAME = "----";
	private static final String DBNAME   = "----";
	private static final String USERNAME = "----";              
	private static final String PASSWORD = "-----";  

	// Database connection string
	// i build jdbc url in one shot so everywhere else i just call DriverManager.getConnection(URL)
	final static String URL = String.format("jdbc:sqlserver://%s:1433;database=%s;user=%s;password=%s;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;",
				HOSTNAME, DBNAME, USERNAME, PASSWORD);

	// Query templates
	// these map 1:1 to my menu options, so i dont forget parameter order
	static final String QUERY_TEMPLATE_1  = "EXEC dbo.InsertVisitorAndEnroll ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?";
	static final String QUERY_TEMPLATE_2  = "EXEC dbo.InsertRangerAndAssign ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?";
	static final String QUERY_TEMPLATE_3  = "EXEC dbo.InsertTeamAndLeader ?, ?, ?, ?";
	static final String QUERY_TEMPLATE_4  = "EXEC dbo.InsertDonation ?, ?, ?, ?, ?, ?, ?, ?, ?";
	static final String QUERY_TEMPLATE_5  = "EXEC dbo.InsertResearcherAndAssign ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?";
	static final String QUERY_TEMPLATE_6  = "EXEC dbo.InsertTeamReport ?, ?, ?, ?";
	static final String QUERY_TEMPLATE_7  = "EXEC dbo.InsertProgram ?, ?, ?, ?, ?";
	static final String QUERY_TEMPLATE_8  = "EXEC dbo.GetEmergencyContacts ?";
	static final String QUERY_TEMPLATE_9  = "EXEC dbo.GetVisitorsInProgram ?, ?";
	static final String QUERY_TEMPLATE_10 = "EXEC dbo.GetProgramsInParkAfter ?, ?";
	static final String QUERY_TEMPLATE_11 = "EXEC dbo.GetMonthlyAnonDonationAgg ?, ?";
	static final String QUERY_TEMPLATE_12 = "EXEC dbo.GetTeamRangersWithDetails ?";
	static final String QUERY_TEMPLATE_13 = "EXEC dbo.GetAllIndividualsMailing";
	static final String QUERY_TEMPLATE_14 = "EXEC dbo.BumpResearcherSalaryForMultiTeams";
	static final String QUERY_TEMPLATE_15 = "EXEC dbo.DeleteIdleVisitors";

	// i print this as the main menu. simple and long, but easy to scan for me
	static final String PROMPT =
		"\nWELCOME TO THE NATIONAL PARK SERVICE SYSTEM DATABASE\n" +
		"(1) Insert a new visitor into the database and associate them with one or more park programs\n" +
		"(2) Insert a new ranger into the database and assign them to a ranger team\n" +
		"(3) Insert a new ranger team into the database and set its leader\n" +
		"(4) Insert a new donation from a donor\n" +
		"(5) Insert a new researcher into the database and associate them with one or more ranger teams\n" +
		"(6) Insert a report submitted by a ranger team to a researcher\n" +
		"(7) Insert a new park program into the database for a specific park\n" +
		"(8) Retrieve the names and contact information of all emergency contacts for a specific person\n" +
		"(9) Retrieve the list of visitors enrolled in a specific park program, including their accessibility needs\n" +
		"(10) Retrieve all park programs for a specific park that started after a given date\n" +
		"(11) Retrieve the total and average donation amount received in a month from all anonymous donors. The result must be sorted by total amount of the donation in descending order\n" +
		"(12) Retrieve the list of rangers in a team, including their certifications, years of service and their role in the team (leader or member)\n" +
		"(13) Retrieve the names, IDs, contact information, and newsletter subscription status of all individuals in the database\n" +
		"(14) Update the salary of researchers overseeing more than one ranger team by a 3% increase\n" +
		"(15) Delete visitors who have not enrolled in any park programs and whose park passes have expired\n" +
		"(16) Import Ranger Teams Data\n" +
		"(17) Export to Retrieve names and mailing addresses of all people on the mailing list\r\n" +
		"(18) Quit";

	public static void main(String[] args) throws SQLException {
		System.out.println("Welcome to the NPSS Application!");

		final Scanner sc = new Scanner(System.in);
		String option = "";
		// loop until user types 18. im doing a small while + switch, very basic cli
		while (!option.equals("18")) {
			System.out.println(PROMPT);
			option = sc.next();
			sc.nextLine(); // consume leftover newline after next()

			switch (option) {
				case "1": { // Insert visitor & enroll
					// I collect every field one by one, so user dont get confused
					System.out.println("IDNumber:"); String id = sc.nextLine();
					System.out.println("FirstName:"); String fn = sc.nextLine();
					System.out.println("MiddleName (blank ok):"); String mi = blankToNull(sc.nextLine());
					System.out.println("LastName:"); String ln = sc.nextLine();
					System.out.println("DOB (YYYY-MM-DD):"); String dob = sc.nextLine();
					System.out.println("Gender:"); String gender = sc.nextLine();
					System.out.println("Street:"); String street = sc.nextLine();
					System.out.println("City:"); String city = sc.nextLine();
					System.out.println("State:"); String state = sc.nextLine();
					System.out.println("PostalCode:"); String pc = sc.nextLine();
					System.out.println("IsSubscribed (0/1):"); int sub = Integer.parseInt(sc.nextLine());
					System.out.println("ParkName:"); String park = sc.nextLine();
					System.out.println("ProgramName:"); String prog = sc.nextLine();
					System.out.println("VisitDate (YYYY-MM-DD):"); String vdate = sc.nextLine();
					System.out.println("Accessibility (blank ok):"); String acc = blankToNull(sc.nextLine());

					// try-with-resources — auto closes conn + stmt, so i dont leak anything
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_1)) {
						s.setString(1, id); s.setString(2, fn); s.setString(3, mi); s.setString(4, ln);
						s.setDate(5, Date.valueOf(dob)); s.setString(6, gender);
						s.setString(7, street); s.setString(8, city); s.setString(9, state); s.setString(10, pc);
						s.setBoolean(11, sub==1);
						s.setString(12, park); s.setString(13, prog);
						s.setDate(14, Date.valueOf(vdate)); s.setString(15, acc);
						int n = s.executeUpdate();
						System.out.printf("Done. %d rows affected.%n", n);
					}
					break;
				}
				case "2": { // Insert ranger & assign
					// create ranger profile + push them into selected team (one-team rule is in SQL side)
					System.out.println("IDNumber:"); String id = sc.nextLine();
					System.out.println("FirstName:"); String fn = sc.nextLine();
					System.out.println("MiddleName (blank ok):"); String mi = blankToNull(sc.nextLine());
					System.out.println("LastName:"); String ln = sc.nextLine();
					System.out.println("DOB (YYYY-MM-DD):"); String dob = sc.nextLine();
					System.out.println("Gender:"); String gender = sc.nextLine();
					System.out.println("Street:"); String street = sc.nextLine();
					System.out.println("City:"); String city = sc.nextLine();
					System.out.println("State:"); String state = sc.nextLine();
					System.out.println("PostalCode:"); String pc = sc.nextLine();
					System.out.println("IsSubscribed (0/1):"); int sub = Integer.parseInt(sc.nextLine());
					System.out.println("StartDate (YYYY-MM-DD):"); String sdt = sc.nextLine();
					System.out.println("Status (active/inactive):"); String st = sc.nextLine();
					System.out.println("TeamID:"); String team = sc.nextLine();

					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_2)) {
						s.setString(1, id); s.setString(2, fn); s.setString(3, mi); s.setString(4, ln);
						s.setDate(5, Date.valueOf(dob)); s.setString(6, gender);
						s.setString(7, street); s.setString(8, city); s.setString(9, state); s.setString(10, pc);
						s.setBoolean(11, sub==1);
						s.setDate(12, Date.valueOf(sdt)); s.setString(13, st); s.setString(14, team);
						int n = s.executeUpdate();
						System.out.printf("Done. %d rows affected.%n", n);
					}
					break;
				}
				case "3": { // Insert team & set leader
					// i create the team first, then mark the leader (leader must also be a ranger)
					System.out.println("TeamID:"); String team = sc.nextLine();
					System.out.println("FocusArea:"); String fa = sc.nextLine();
					System.out.println("FormationDate (YYYY-MM-DD):"); String fdt = sc.nextLine();
					System.out.println("LeaderID:"); String leader = sc.nextLine();
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_3)) {
						s.setString(1, team); s.setString(2, fa);
						s.setDate(3, Date.valueOf(fdt)); s.setString(4, leader);
						int n = s.executeUpdate();
						System.out.printf("Done. %d rows affected.%n", n);
					}
					break;
				}
				case "4": { // Insert donation
					// supports both CHECK and CARD, i let user pick and then fill proper params
					System.out.println("Donor IDNumber:"); String id = sc.nextLine();
					System.out.println("DonationDate (YYYY-MM-DD):"); String ddate = sc.nextLine();
					System.out.println("Amount (e.g., 150.00):"); String amt = sc.nextLine();
					System.out.println("CampaignName (blank ok):"); String camp = blankToNull(sc.nextLine());
					System.out.println("PaymentType (CHECK/CARD):"); String ptype = sc.nextLine();
					String chk=null, ctype=null, last4=null, exp=null;
					if ("CHECK".equalsIgnoreCase(ptype)) {
						System.out.println("CheckNumber:"); chk = sc.nextLine();
					} else {
						System.out.println("CardType:"); ctype = sc.nextLine();
						System.out.println("LastFour (4 digits):"); last4 = sc.nextLine();
						System.out.println("Expiration (YYYY-MM-DD):"); exp = sc.nextLine();
					}
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_4)) {
						s.setString(1, id);
						s.setDate(2, Date.valueOf(ddate));
						s.setBigDecimal(3, new java.math.BigDecimal(amt));
						s.setString(4, camp);
						s.setString(5, ptype);
						s.setString(6, chk);
						s.setString(7, ctype);
						s.setString(8, last4);
						if (exp==null) s.setNull(9, Types.DATE); else s.setDate(9, Date.valueOf(exp));
						int n = s.executeUpdate();
						System.out.printf("Done. %d rows affected.%n", n);
					}
					break;
				}
				case "5": { // Insert researcher & assign team
					// researcher shares the same Person.IDNumber (no separate researcher id in my model)
					System.out.println("IDNumber:"); String id = sc.nextLine();
					System.out.println("FirstName:"); String fn = sc.nextLine();
					System.out.println("MiddleName (blank ok):"); String mi = blankToNull(sc.nextLine());
					System.out.println("LastName:"); String ln = sc.nextLine();
					System.out.println("DOB (YYYY-MM-DD):"); String dob = sc.nextLine();
					System.out.println("Gender:"); String gender = sc.nextLine();
					System.out.println("Street:"); String street = sc.nextLine();
					System.out.println("City:"); String city = sc.nextLine();
					System.out.println("State:"); String state = sc.nextLine();
					System.out.println("PostalCode:"); String pc = sc.nextLine();
					System.out.println("IsSubscribed (0/1):"); int sub = Integer.parseInt(sc.nextLine());
					System.out.println("ResearchField:"); String rf = sc.nextLine();
					System.out.println("HireDate (YYYY-MM-DD):"); String hdt = sc.nextLine();
					System.out.println("Salary (e.g., 70000.00):"); String sal = sc.nextLine();
					System.out.println("TeamID:"); String team = sc.nextLine();
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_5)) {
						s.setString(1,id); s.setString(2,fn); s.setString(3,mi); s.setString(4,ln);
						s.setDate(5, Date.valueOf(dob)); s.setString(6, gender);
						s.setString(7,street); s.setString(8,city); s.setString(9,state); s.setString(10,pc);
						s.setBoolean(11, sub==1);
						s.setString(12, rf);
						s.setDate(13, Date.valueOf(hdt));
						s.setBigDecimal(14, new java.math.BigDecimal(sal));
						s.setString(15, team);
						int n = s.executeUpdate();
						System.out.printf("Done. %d rows affected.%n", n);
					}
					break;
				}
				case "6": { // Insert report
					// here i take team + researcher person id (same IDNumber) and a tiny summary
					System.out.println("TeamID:"); String team = sc.nextLine();
					System.out.println("Researcher IDNumber:"); String rid = sc.nextLine();
					System.out.println("ReportDate (YYYY-MM-DD):"); String rdt = sc.nextLine();
					System.out.println("SummaryOfActivities:"); String sum = sc.nextLine();
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_6)) {
						s.setString(1, team); s.setString(2, rid);
						s.setDate(3, Date.valueOf(rdt)); s.setString(4, sum);
						int n = s.executeUpdate();
						System.out.printf("Done. %d rows affected.%n", n);
					}
					break;
				}
				case "7": { // Insert program
					// simple upsert happens inside stored proc, i just pass data
					System.out.println("ParkName:"); String park = sc.nextLine();
					System.out.println("ProgramName:"); String prog = sc.nextLine();
					System.out.println("Type:"); String type = sc.nextLine();
					System.out.println("StartDate (YYYY-MM-DD):"); String sdt = sc.nextLine();
					System.out.println("Duration (hours, int):"); int dur = Integer.parseInt(sc.nextLine());
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_7)) {
						s.setString(1, park); s.setString(2, prog); s.setString(3, type);
						s.setDate(4, Date.valueOf(sdt)); s.setInt(5, dur);
						int n = s.executeUpdate();
						System.out.printf("Done. %d rows affected.%n", n);
					}
					break;
				}
				case "8": { // Emergency contacts
					// read-only report. im just printing columns in plain text, nothing fancy
					System.out.println("Person IDNumber:"); String id = sc.nextLine();
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_8)) {
						s.setString(1, id);
						try (ResultSet rs = s.executeQuery()) {
							System.out.println("ContactName | Relationship | PhoneNumber");
							while (rs.next()) {
								System.out.printf("%s | %s | %s%n",
									rs.getString(1), rs.getString(2), rs.getString(3));
							}
						}
					}
					break;
				}
				case "9": { // Visitors in program
					System.out.println("ParkName:"); String park = sc.nextLine();
					System.out.println("ProgramName:"); String prog = sc.nextLine();
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_9)) {
						s.setString(1, park); s.setString(2, prog);
						try (ResultSet rs = s.executeQuery()) {
							System.out.println("IDNumber | FirstName | LastName | VisitDate | Accessibility");
							while (rs.next()) {
								System.out.printf("%s | %s | %s | %s | %s%n",
									rs.getString(1), rs.getString(2), rs.getString(3),
									rs.getString(4), rs.getString(5));
							}
						}
					}
					break;
				}
				case "10": { // Programs after date
					System.out.println("ParkName:"); String park = sc.nextLine();
					System.out.println("After Date (YYYY-MM-DD):"); String dt = sc.nextLine();
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_10)) {
						s.setString(1, park); s.setDate(2, Date.valueOf(dt));
						try (ResultSet rs = s.executeQuery()) {
							System.out.println("ParkName | ProgramName | Type | StartDate | Duration");
							while (rs.next()) {
								System.out.printf("%s | %s | %s | %s | %s%n",
									rs.getString(1), rs.getString(2), rs.getString(3),
									rs.getString(4), rs.getString(5));
							}
						}
					}
					break;
				}
				case "11": { // Monthly anon donations
					// i pass month/year to the SP and then just dump the result table to console
					System.out.println("Year (YYYY):"); int yr = Integer.parseInt(sc.nextLine());
					System.out.println("Month (1-12):"); int mo = Integer.parseInt(sc.nextLine());
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_11)) {
						s.setInt(1, yr); s.setInt(2, mo);
						try (ResultSet rs = s.executeQuery()) {
							System.out.println("IDNumber | FirstName | LastName | Total | Avg | Count");
							while (rs.next()) {
								System.out.printf("%s | %s | %s | %s | %s | %s%n",
									rs.getString(1), rs.getString(2), rs.getString(3),
									rs.getString(4), rs.getString(5), rs.getString(6));
							}
						}
					}
					break;
				}
				case "12": { // Team rangers with details
					System.out.println("TeamID:"); String team = sc.nextLine();
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_12)) {
						s.setString(1, team);
						try (ResultSet rs = s.executeQuery()) {
							System.out.println("IDNumber | FirstName | LastName | Years | Certification | Role");
							while (rs.next()) {
								System.out.printf("%s | %s | %s | %s | %s | %s%n",
									rs.getString(1), rs.getString(2), rs.getString(3),
									rs.getString(4), rs.getString(5), rs.getString(6));
							}
						}
					}
					break;
				}
				case "13": { // All individuals (contacts/subscription)
					// tiny export-style listing of everyone with contact info combined
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_13);
						 ResultSet rs = s.executeQuery()) {
						System.out.println("ID | First | Last | Street | City | State | Zip | Emails | Phones | Subscribed");
						while (rs.next()) {
							System.out.printf("%s | %s | %s | %s | %s | %s | %s | %s | %s | %s%n",
								rs.getString(1), rs.getString(2), rs.getString(3),
								rs.getString(4), rs.getString(5), rs.getString(6), rs.getString(7),
								rs.getString(8), rs.getString(9), rs.getString(10));
						}
					}
					break;
				}
				case "14": { // Raise salaries
					// gives 3% bump if a researcher is linked to more than one team (logic inside DB)
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_14)) {
						int n = s.executeUpdate();
						System.out.printf("Done. %d rows affected.%n", n);
					}
					break;
				}
				case "15": { // Delete idle visitors
					// small cleanup option. i just call SP and print how many deleted
					try (Connection c = DriverManager.getConnection(URL);
						 PreparedStatement s = c.prepareStatement(QUERY_TEMPLATE_15)) {
						int n = s.executeUpdate();
						System.out.printf("Done. %d visitors deleted.%n", n);
					}
					break;
				}
				case "16": { // Import teams from CSV (TeamID,FocusArea,FormationDate)
					System.out.println("Input CSV path:");
					String inPath = sc.nextLine();
					try (Connection c = DriverManager.getConnection(URL)) {
						int ok = 0, fail = 0, lineNo = 0;
						// i read file line by line, split by comma. not bullet proof but okay for course project
						try (BufferedReader br = Files.newBufferedReader(Paths.get(inPath))) {
							String line;
							while ((line = br.readLine()) != null) {
								lineNo++;
								if (line.trim().isEmpty()) continue; // skip blank lines
								String[] t = line.split(",", -1);
								String team  = t[0].trim();
								String focus = t[1].trim();
								String fdt   = t[2].trim();

								try (PreparedStatement st = c.prepareStatement(
										"INSERT INTO RangerTeam(TeamID, FocusArea, FormationDate) VALUES (?,?,?)")) {
									st.setString(1, team);
									st.setString(2, focus);
									st.setDate(3, Date.valueOf(fdt));
									st.executeUpdate();
									ok++;
								} catch (SQLException ex) {
									fail++; // e.g., duplicate TeamID or bad date, i just count it
								}
							}
						} catch (IOException ioe) {
							System.err.println("File read error: " + ioe.getMessage());
						}
						System.out.printf("Import complete. OK=%d, Failed=%d%n", ok, fail);
					}
					break;
				}
				case "17": { // Export mailing list to CSV (IsSubscribed=1)
					System.out.println("Output CSV path:");
					String outPath = sc.nextLine();
					try (Connection c = DriverManager.getConnection(URL);
						 Statement st = c.createStatement();
						 ResultSet rs = st.executeQuery(
							"SELECT IDNumber, FirstName, LastName, Street, City, State, PostalCode " +
							"FROM Person WHERE IsSubscribed=1 ORDER BY LastName, FirstName");
						 BufferedWriter bw = Files.newBufferedWriter(Paths.get(outPath))) {

						bw.write("IDNumber,FirstName,LastName,Street,City,State,PostalCode");
						bw.newLine();
						while (rs.next()) {
							bw.write(String.join(",",
								csv(rs.getString(1)), csv(rs.getString(2)), csv(rs.getString(3)),
								csv(rs.getString(4)), csv(rs.getString(5)), csv(rs.getString(6)),
								csv(rs.getString(7))));
							bw.newLine();
						}
						System.out.println("Export complete.");
					} catch (IOException ioe) {
						System.err.println("File write error."); ioe.printStackTrace();
					}
					break;
				}
				case "18":
					System.out.println("Exiting! Goodbye!");
					break;
				default:
					System.out.println("Unrecognized option. Try again.");
			}
		}
		sc.close();
	}

	private static String blankToNull(String s) { return (s==null || s.isEmpty()) ? null : s; }

	// small helper for CSV escaping
	private static String csv(String s) {
		if (s == null) return "";
		String v = s.replace("\"","\"\"");
		if (v.contains(",") || v.contains("\"") || v.contains("\n")) return "\"" + v + "\"";
		return v;
	}
}