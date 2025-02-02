/* eslint-disable */
// this is an auto generated file. This will be overwritten

export const onCreateChannel = /* GraphQL */ `
  subscription OnCreateChannel(
    $filter: ModelSubscriptionChannelFilterInput
    $owner: String
  ) {
    onCreateChannel(filter: $filter, owner: $owner) {
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
export const onUpdateChannel = /* GraphQL */ `
  subscription OnUpdateChannel(
    $filter: ModelSubscriptionChannelFilterInput
    $owner: String
  ) {
    onUpdateChannel(filter: $filter, owner: $owner) {
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
export const onDeleteChannel = /* GraphQL */ `
  subscription OnDeleteChannel(
    $filter: ModelSubscriptionChannelFilterInput
    $owner: String
  ) {
    onDeleteChannel(filter: $filter, owner: $owner) {
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
export const onCreateMessage = /* GraphQL */ `
  subscription OnCreateMessage(
    $filter: ModelSubscriptionMessageFilterInput
    $owner: String
  ) {
    onCreateMessage(filter: $filter, owner: $owner) {
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
export const onUpdateMessage = /* GraphQL */ `
  subscription OnUpdateMessage(
    $filter: ModelSubscriptionMessageFilterInput
    $owner: String
  ) {
    onUpdateMessage(filter: $filter, owner: $owner) {
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
export const onDeleteMessage = /* GraphQL */ `
  subscription OnDeleteMessage(
    $filter: ModelSubscriptionMessageFilterInput
    $owner: String
  ) {
    onDeleteMessage(filter: $filter, owner: $owner) {
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
export const onCreateLastActivity = /* GraphQL */ `
  subscription OnCreateLastActivity(
    $filter: ModelSubscriptionLastActivityFilterInput
    $owner: String
  ) {
    onCreateLastActivity(filter: $filter, owner: $owner) {
      userId
      log
      createdAt
      updatedAt
      owner
      __typename
    }
  }
`;
export const onUpdateLastActivity = /* GraphQL */ `
  subscription OnUpdateLastActivity(
    $filter: ModelSubscriptionLastActivityFilterInput
    $owner: String
  ) {
    onUpdateLastActivity(filter: $filter, owner: $owner) {
      userId
      log
      createdAt
      updatedAt
      owner
      __typename
    }
  }
`;
export const onDeleteLastActivity = /* GraphQL */ `
  subscription OnDeleteLastActivity(
    $filter: ModelSubscriptionLastActivityFilterInput
    $owner: String
  ) {
    onDeleteLastActivity(filter: $filter, owner: $owner) {
      userId
      log
      createdAt
      updatedAt
      owner
      __typename
    }
  }
`;
