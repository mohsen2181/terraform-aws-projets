const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: 'us-east-1_j9wCNoCtn',
      userPoolClientId: '7v2uargikedpmoha4k91ce74pf',
      loginWith: {
        email: true,
      },
    }
  },
  API: {
    baseUrl: 'https://rylu5a92dd.execute-api.us-east-1.amazonaws.com'
  }
};

export default awsConfig;
