/* eslint-disable */
// this is an auto generated file. This will be overwritten

export const createChannel = /* GraphQL */ `
  mutation CreateChannel(
    $input: CreateChannelInput!
    $condition: ModelChannelConditionInput
  ) {
    createChannel(input: $input, condition: $condition) {
      id
      name
      description
      icon
      messges {
        items {
          id
          channelId
          content
          createdAt
          updatedAt
          owner
          __typename
        }
        nextToken
        __typename
      }
      groups
      createdAt
      updatedAt
      owner
      __typename
    }
  }
`;
export const updateChannel = /* GraphQL */ `
  mutation UpdateChannel(
    $input: UpdateChannelInput!
    $condition: ModelChannelConditionInput
  ) {
    updateChannel(input: $input, condition: $condition) {
      id
      name
      description
      icon
      messges {
        items {
          id
          channelId
          content
          createdAt
          updatedAt
          owner
          __typename
        }
        nextToken
        __typename
      }
      groups
      createdAt
      updatedAt
      owner
      __typename
    }
  }
`;
export const deleteChannel = /* GraphQL */ `
  mutation DeleteChannel(
    $input: DeleteChannelInput!
    $condition: ModelChannelConditionInput
  ) {
    deleteChannel(input: $input, condition: $condition) {
      id
      name
      description
      icon
      messges {
        items {
          id
          channelId
          content
          createdAt
          updatedAt
          owner
          __typename
        }
        nextToken
        __typename
      }
      groups
      createdAt
      updatedAt
      owner
      __typename
    }
  }
`;
export const createMessage = /* GraphQL */ `
  mutation CreateMessage(
    $input: CreateMessageInput!
    $condition: ModelMessageConditionInput
  ) {
    createMessage(input: $input, condition: $condition) {
      id
      channelId
      content
      createdAt
      updatedAt
      owner
      __typename
    }
  }
`;
export const updateMessage = /* GraphQL */ `
  mutation UpdateMessage(
    $input: UpdateMessageInput!
    $condition: ModelMessageConditionInput
  ) {
    updateMessage(input: $input, condition: $condition) {
      id
      channelId
      content
      createdAt
      updatedAt
      owner
      __typename
    }
  }
`;
export const deleteMessage = /* GraphQL */ `
  mutation DeleteMessage(
    $input: DeleteMessageInput!
    $condition: ModelMessageConditionInput
  ) {
    deleteMessage(input: $input, condition: $condition) {
      id
      channelId
      content
      createdAt
      updatedAt
      owner
      __typename
    }
  }
`;
export const createLastActivity = /* GraphQL */ `
  mutation CreateLastActivity(
    $input: CreateLastActivityInput!
    $condition: ModelLastActivityConditionInput
  ) {
    createLastActivity(input: $input, condition: $condition) {
      userId
      log
      createdAt
      updatedAt
      owner
      __typename
    }
  }
`;
export const updateLastActivity = /* GraphQL */ `
  mutation UpdateLastActivity(
    $input: UpdateLastActivityInput!
    $condition: ModelLastActivityConditionInput
  ) {
    updateLastActivity(input: $input, condition: $condition) {
      userId
      log
      createdAt
      updatedAt
      owner
      __typename
    }
  }
`;
export const deleteLastActivity = /* GraphQL */ `
  mutation DeleteLastActivity(
    $input: DeleteLastActivityInput!
    $condition: ModelLastActivityConditionInput
  ) {
    deleteLastActivity(input: $input, condition: $condition) {
      userId
      log
      createdAt
      updatedAt
      owner
      __typename
    }
  }
`;
