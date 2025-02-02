// ui
import React, { useEffect, useState } from "react";
import {
  Alert, Button, Box, Container, Form,
  Grid, Header, Link, Modal,
  SpaceBetween, Textarea
} from "@cloudscape-design/components";

// utils
import moment from "moment";

// components
import { logLastActivity, retrieveLastActivity } from './Activity'

// apis
import { useAsyncData } from './DataProvider'
import { Analytics, API, graphqlOperation } from 'aws-amplify'
import { listChannels, listMessages } from '../graphql/queries'
import { createMessage, updateMessage, deleteMessage } from '../graphql/mutations'
import { onCreateMessage, onUpdateMessage, onDeleteMessage } from '../graphql/subscriptions';

export const Chat = props => {
  const [channels, setChannels] = useAsyncData(() => fetchChannelApi());
  const [context, setContext] = useState({channel: null});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    retrieveLastActivity(props.userId).then((activity) => {
      if (loading) {
        if (activity != null) {
          setContext(JSON.parse(activity.log));
        }
        setLoading(false);
      }
    });
  }, []);

  return (
    <Box>
      <Grid gridDefinition={[{ colspan: 3 }, { colspan: 9 }]}>
        <Container>
          <SpaceBetween size="s">
            <Box>
            {
              channels.map(channel =>
                <Channel
                  key={channel.id}
                  userId={props.userId}
                  channel={channel}
                  context={context}
                  setContext={setContext}
                />
              )
            }
            </Box>
          </SpaceBetween>
        </Container>
        <Messages
          context={context}
          setContext={setContext}
          alerts={props.alerts}
          setAlerts={props.setAlerts}
        />
      </Grid>
    </Box>
  );
}

const Channel = ({
  userId,
  channel,
  context,
  setContext,
}) => {
  if (!context.channel || context.channel == null) {
    setContext({...context, ...{channel: channel.id}});
  }

  const switchChannelHandler = () => {
    const updateContext = {...context, ...{channel: channel.id}};
    setContext(updateContext);
    logLastActivity(userId, updateContext);
  }

  return (
    <Box>
      <Link onFollow={switchChannelHandler}>{channel.name}</Link>
    </Box>
  );
}

const Messages = props => {
  const [activeMessage, setActiveMessage] = useState(null);
  const [messages, setMessages] = useState([]);

  useEffect(() => {
    const fetchMessages = async () => {
      const result = await API.graphql(graphqlOperation(listMessages, {filter: {channelId: {eq: props.context.channel}}}))
      setMessages(result.data.listMessages.items.filter(item => item._deleted !== true))
    }
    fetchMessages()

    const createSub = API.graphql(graphqlOperation(onCreateMessage)).subscribe({
      next: ({ value }) => { setMessages((messages) => [...messages, value.data.onCreateMessage]) }
    })

    const updateSub = API.graphql(graphqlOperation(onUpdateMessage)).subscribe({
      next: ({ value }) => {
        setMessages(messages => {
          const toUpdateIndex = messages.findIndex(item => item.id === value.data.onUpdateMessage.id)
          if (toUpdateIndex === - 1) { // If the message doesn't exist, treat it like an "add"
            return [...messages, value.data.onUpdateMessage]
          }
          return [...messages.slice(0, toUpdateIndex), value.data.onUpdateMessage, ...messages.slice(toUpdateIndex + 1)]
        })
      }
    })

    const deleteSub = API.graphql(graphqlOperation(onDeleteMessage)).subscribe({
      next: ({ value }) => {
        setMessages(messages => {
          const toDeleteIndex = messages.findIndex(item => item.id === value.data.onDeleteMessage.id)
          return [...messages.slice(0, toDeleteIndex), ...messages.slice(toDeleteIndex + 1)]
        })
      }
    })

    return () => {
      createSub.unsubscribe()
      updateSub.unsubscribe()
      deleteSub.unsubscribe()
    }
  }, [props.context.channel])

  return (
    <Box>
      <SpaceBetween size="s">
        <Container>
          <div style={{maxHeight:'360px',overflow:'auto',}}>
            <SpaceBetween size="xs">
            {
              messages.length > 0 ? (messages.sort((b, a) => b.createdAt.localeCompare(a.createdAt)).map(message =>
                <Message
                  key={message.id}
                  message={message}
                  activeMessage={activeMessage}
                  setActiveMessage={setActiveMessage}
                  alerts={props.alerts}
                  setAlerts={props.setAlerts}
                />
              )) : <NoMessage />
            }
            </SpaceBetween>
          </div>
        </Container>
        <Container>
          <MessageForm
            channelId={props.context.channel}
            alerts={props.alerts}
            setAlerts={props.setAlerts}
          />
        </Container>
      </SpaceBetween>
    </Box>
  );
}

function NewLineToBr({children = ""}) {
  return children.split('\n').reduce(function (arr, line) {
    return arr.concat(line, <br />);
  },[]);
}

const NoMessage = () => {
  return (
    <SpaceBetween size="l">
      <Box
        margin={{ vertical: 'xs' }}
        fontSize="heading-s"
        textAlign="center"
        color="inherit"
      >
        Please leave a message
      </Box>
    </SpaceBetween>
  );
}

const Message = ({
  message,
  activeMessage,
  setActiveMessage,
  alerts,
  setAlerts,
}) => {
  const [confirmVisible, setConfirmVisible] = useState(false);
  const isEditing = activeMessage && activeMessage.type === "edit" && activeMessage.id === message.id
  const deleteHandler = () => {
    deleteMessageApi(message.id, message._version, alerts, setAlerts);
    setConfirmVisible(false);
  }

  return (
    isEditing ?
    <MessageForm
      initText={message.content}
      channelId={message.channelId}
      messageId={message.id}
      messageVersion={message._version}
      activeMessage={activeMessage}
      setActiveMessage={setActiveMessage}
      alerts={alerts}
      setAlerts={setAlerts}
    /> : <>
    <Header
      variant="h5"
      actions={
        <Box>
          <SpaceBetween direction="horizontal" size="xxs">
            <Button iconName="contact" variant="icon" />
            <Button iconName="edit" variant="icon" onClick={() => setActiveMessage({ id: message.id, type: "edit"})} />
            <Button iconName="remove" variant="icon" onClick={() => setConfirmVisible(true)} />
          </SpaceBetween>
        </Box>
      }
    >
      <Box variant="h4">{message.owner}</Box>
      <Box color="text-body-secondary">{moment(message.createdAt).fromNow()}</Box>
    </Header>
    <Box>
      <NewLineToBr>{message.content}</NewLineToBr>
    </Box>
    <Modal
      onDismiss={() => setConfirmVisible(false)}
      visible={confirmVisible}
      closeAriaLabel="Close modal"
      size="medium"
      header="Delete message"
      footer={
        <Box float="right">
          <SpaceBetween direction="horizontal" size="xs">
            <Button variant="link" onClick={() => setConfirmVisible(false)}>Cancel</Button>
            <Button variant="primary" onClick={deleteHandler}>OK</Button>
          </SpaceBetween>
        </Box>
      }
    >
      Are you sure you want to delete this message? This cannot be undone.
      <Alert statusIconAriaLabel="Info">
        Proceeding with this action will delete the message and can affect related resources.{' '}
        <Link external={true} href="https://cloudscape.design/" ariaLabel="Learn more about this, opens in new tab">
          Learn more
        </Link>
      </Alert>
    </Modal>
    </>
  );
}

const MessageForm = ({
  initText = '',
  channelId,
  messageId,
  messageVersion,
  activeMessage,
  setActiveMessage,
  alerts,
  setAlerts,
}) => {
  const [post, setPost] = useState(initText);

  const sendMessage = () => {
    if (post.replace(/\s/g, '').length > 0) {
      if (activeMessage && activeMessage.type === "edit") {
        editMessageApi(messageId, messageVersion, post.trim(), alerts, setAlerts);
        setActiveMessage(null);
      }
      else {
        createMessageApi(channelId, post.trim());
        setPost("");
      }
    }
  };
  const keyUpHandler = (e) => {
    if (e.detail.keyCode === 13 && !e.detail.shiftKey) {
      sendMessage();
      setPost("");
    }
  };
  const submitHandler = (e) => {
    e.preventDefault();
    sendMessage();
  };
  const cancelHandler = () => {
    activeMessage && activeMessage.type === "edit" ? setActiveMessage(null) : setPost("")
  };

  return (
    <form onSubmit={submitHandler}>
    <Form
      actions={
        <Box>
          <SpaceBetween direction="horizontal" size="xxs">
            <Button formAction="none" iconName="undo" variant="icon" onClick={cancelHandler} />
            <Button formAction="submit" iconName="caret-right-filled" variant="icon" />
          </SpaceBetween>
        </Box>
      }
    >
      <Textarea
        onChange={({detail}) => setPost(detail.value)}
        onKeyUp={keyUpHandler}
        value={post}
        rows={post.split(/\r\n|\r|\n/).length}
      />
    </Form>
    </form>
  );
}

// graphql apis
function fetchChannelApi() {
  try {
    return API.graphql(graphqlOperation(listChannels)).then(
      result => {
        return result.data.listChannels.items;
    });
  }
  catch (err) {
    console.log({err});
  }
}

function createMessageApi(channelId, post) {
  try {
    // record a custom event
    Analytics.record({
      name: 'albumVisit',
      attributes: { genre: 'Pop', artist: 'BTS' },
      metrics: { minutesListened: 30 }
    });

    // record a modetization event
    Analytics.record({
      name: '_monetization.purchase',
      attributes: {
        _currency: 'USD',
        _product_id: 'XYZ',
      },
      metrics: {
        _item_price: 12.0,
        _quantity: 1.0,
      }
    });

    // post a message
    API.graphql(graphqlOperation(createMessage, {
      input: { content: post, channelId: channelId }
    }));
  }
  catch (err) {
    console.error(err);
  }
}

async function editMessageApi(messageId, messageVersion, post, alerts, setAlerts) {
  try {
    const result = await API.graphql(graphqlOperation(updateMessage, {
      input: { id: messageId, content: post, _version: messageVersion }
    }));

    return result.data.editMessage;
  }
  catch (err) {
    console.error(err);

    if ("Unauthorized" === err.errors[0].errorType) {
      setAlerts([].concat(alerts, {
          type: "error",
          dismissible: true,
          dismissLabel: "Dismiss message",
          header: ("Failed to edit the message id: " + messageId),
          content: err.errors[0].message,
          id: alerts.length + 1,
          onDismiss: () => setAlerts(items => items.filter(item => item.id !== alerts.length + 1))
        })
      );
    }
  }
}

async function deleteMessageApi(messageId, messageVersion, alerts, setAlerts) {
  try {
    const result = await API.graphql(graphqlOperation(deleteMessage, {
      input: { id: messageId, _version: messageVersion }
    }));

    return result.data.deleteMessage;
  }
  catch (err) {
    console.error(err);

    if ("Unauthorized" === err.errors[0].errorType) {
      setAlerts([].concat(alerts, {
          type: "error",
          dismissible: true,
          dismissLabel: "Dismiss message",
          header: ("Failed to delete the message id: " + messageId),
          content: err.errors[0].message,
          id: alerts.length + 1,
          onDismiss: () => setAlerts(items => items.filter(item => item.id !== alerts.length + 1))
        })
      );
    }
  }
}
