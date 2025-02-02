// ui
import React, { useState, useRef } from "react";
import {
  AppLayout,
  Box,
  ContentLayout,
  Flashbar,
  Header,
  SpaceBetween
} from "@cloudscape-design/components";
import { withAuthenticator } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';

// components
import { Navigation, NavigationBar } from "./components/Navigation";
import { Chat } from "./components/Chat";
import { Admin } from "./components/Admin";

// application
function App({ signOut, user }) {
  const appLayout = useRef();
  const [activeHref, setActiveHref] = React.useState("#/chat");
  const [alerts, setAlerts] = useState([
    {
      type: "error",
      dismissible: true,
      dismissLabel: "Dismiss message",
      header: "Failed to update instance id-4890f893e",
      content: "This is a dismissible error message",
      id: "message_3",
      onDismiss: () => setAlerts(items => items.filter(item => item.id !== "message_3"))
    },
    {
      type: "warning",
      dismissible: true,
      dismissLabel: "Dismiss message",
      content: "This is a warning flash message",
      id: "message_4",
      onDismiss: () => setAlerts(items => items.filter(item => item.id !== "message_4"))
    },
  ]);

  return (
    <Box>
      <NavigationBar signOut={signOut} user={user} />
      <AppLayout
        ref={appLayout}
        headerSelector="#h"
        navigation={<Navigation activeHref={activeHref} setActiveHref={setActiveHref} />}
        content={
          <ContentLayout
            header={
              <SpaceBetween size="m">
                <Header variant="h1" />
                <Flashbar
                  items={alerts}
                  i18nStrings={{
                    ariaLabel: "Notifications",
                    notificationBarAriaLabel: "View all notifications",
                    notificationBarText: "Notifications",
                    errorIconAriaLabel: "Error",
                    warningIconAriaLabel: "Warning",
                    successIconAriaLabel: "Success",
                    infoIconAriaLabel: "Info",
                    inProgressIconAriaLabel: "In progress"
                  }}
                  stackItems
                />
              </SpaceBetween>
            }
          >
            {
              {
                "#/chat" : <Chat userId={user.attributes.sub} alerts={alerts} setAlerts={setAlerts} />,
                "#/admin" : <Admin />,
              }[activeHref]
            }
          </ContentLayout>
        }
      />
    </Box>
  );
}

export default withAuthenticator(App);
