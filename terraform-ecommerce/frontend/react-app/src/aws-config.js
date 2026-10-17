const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: 'us-east-1_QwHPg2g9F',
      userPoolClientId: '2cjrn5mrtrqaa9rrl6ngkuhuep',
      loginWith: {
        email: true,
      },
    }
  },
  API: {
    baseUrl: 'https://bwuhx1uh9j.execute-api.us-east-1.amazonaws.com'
  }
};

export default awsConfig;
