/* eslint-disable */
// this is an auto generated file. This will be overwritten

export const getChannel = /* GraphQL */ `
  query GetChannel($id: ID!) {
    getChannel(id: $id) {
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
export const listChannels = /* GraphQL */ `
  query ListChannels(
    $filter: ModelChannelFilterInput
    $limit: Int
    $nextToken: String
  ) {
    listChannels(filter: $filter, limit: $limit, nextToken: $nextToken) {
      items {
        id
        name
        description
        icon
        messges {
          nextToken
          __typename
        }
        groups
        createdAt
        updatedAt
        owner
        __typename
      }
      nextToken
      __typename
    }
  }
`;
export const getMessage = /* GraphQL */ `
  query GetMessage($id: ID!) {
    getMessage(id: $id) {
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
export const listMessages = /* GraphQL */ `
  query ListMessages(
    $filter: ModelMessageFilterInput
    $limit: Int
    $nextToken: String
  ) {
    listMessages(filter: $filter, limit: $limit, nextToken: $nextToken) {
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
  }
`;
export const getLastActivity = /* GraphQL */ `
  query GetLastActivity($userId: String!) {
    getLastActivity(userId: $userId) {
      userId
      log
      createdAt
      updatedAt
      owner
      __typename
    }
  }
`;
export const listLastActivities = /* GraphQL */ `
  query ListLastActivities(
    $userId: String
    $filter: ModelLastActivityFilterInput
    $limit: Int
    $nextToken: String
    $sortDirection: ModelSortDirection
  ) {
    listLastActivities(
      userId: $userId
      filter: $filter
      limit: $limit
      nextToken: $nextToken
      sortDirection: $sortDirection
    ) {
      items {
        userId
        log
        createdAt
        updatedAt
        owner
        __typename
      }
      nextToken
      __typename
    }
  }
`;
export const messagesByChannelId = /* GraphQL */ `
  query MessagesByChannelId(
    $channelId: ID!
    $sortDirection: ModelSortDirection
    $filter: ModelMessageFilterInput
    $limit: Int
    $nextToken: String
  ) {
    messagesByChannelId(
      channelId: $channelId
      sortDirection: $sortDirection
      filter: $filter
      limit: $limit
      nextToken: $nextToken
    ) {
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
  }
`;
