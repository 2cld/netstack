# ops monitor
- Networkchuck What's Up Gold - https://www.youtube.com/watch?v=-2yzXSIuC8o
- Gatus Website Monitoring https://www.youtube.com/watch?v=vlifG8dCqU8

## IP addresses of clients connecting to your Terminal Services/Remote Desktop Services (RDS) server in the Event Viewer. 
- Open Event Viewer: You can do this by typing eventvwr.msc in the Run dialog box (Win + R) or by navigating through Computer Management.
- Navigate to the relevant log: Expand the following path:
- Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational.
- Filter the log (optional, but recommended):
- Right-click on "Operational" and select "Filter Current Log...".
- Enter Event ID 21 (for new connections) in the "Event IDs" field and click OK.
- Locate the login event: Scroll through the filtered events to find the desired login events.
- Identify the IP Address: Under the "General" tab of the event details, you'll find the "Source Network Address," which is the IP address of the client that connected to your
