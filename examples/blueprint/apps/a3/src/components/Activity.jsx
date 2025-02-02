// apis
import { API, graphqlOperation } from 'aws-amplify'
import { getLastActivity } from '../graphql/queries'
import { createLastActivity, updateLastActivity } from '../graphql/mutations'

// apis
export function retrieveLastActivity(userId) {
  try {
    return API.graphql(graphqlOperation(getLastActivity, {
      userId: userId
    })).then(
      result => {
        return result.data.getLastActivity;
    });
  }
  catch (err) {
    console.error({err});
  }
}

export function logLastActivity(userId, log) {
  try {
    retrieveLastActivity(userId).then((activity) => {
      if (activity && activity != null) {
        API.graphql(graphqlOperation(updateLastActivity, {
          input: { userId: userId, log: JSON.stringify({...JSON.parse(activity.log), ...log}), _version: activity._version }
        }));
      }
      else {
        API.graphql(graphqlOperation(createLastActivity, {
          input: { userId: userId, log: JSON.stringify(log) }
        }));
      }
    });
  }
  catch (err) {
    console.error({err});
  }
}
