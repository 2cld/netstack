# ops monitor
- Jim's Garage [Homelab Monitoring #1](https://www.youtube.com/watch?v=LShvy9l3tzs)
- Jim's Garage [Homelab Monitoring #2](https://www.youtube.com/watch?v=Yr9-QMa7JHw)
- Christian Lempa [Grafana Alloy](https://www.youtube.com/watch?v=E654LPrkCjo)
  - [https://grafana.com/docs/alloy/latest/](https://grafana.com/docs/alloy/latest/)
  - [https://github.com/grafana/alloy-scenarios](https://github.com/grafana/alloy-scenarios)
  - [https://github.com/christianlempa/boilerplates](https://github.com/christianlempa/boilerplates)
- CodeOps by Mo
  - [Part 1: Collecting Logs with Grafana](https://www.youtube.com/watch?v=tMSZ_DVq5pw)
  - [Part 2: Collecting Metrics with Grafana](https://www.youtube.com/watch?v=kDQ-egkmNvE)
  - [Part 3: Building Tracing Pipelines with Alloy](https://www.youtube.com/watch?v=PCF5CYKirx8)
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
