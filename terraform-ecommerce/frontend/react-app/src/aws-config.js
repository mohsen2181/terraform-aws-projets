const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: 'us-east-1_nWt1uSTAM',
      userPoolClientId: 'lm5jj6f7m4hl87netpks9hcsa',
      loginWith: {
        email: true,
      },
    }
  },
  API: {
    baseUrl: 'https://40o9tfnrsk.execute-api.us-east-1.amazonaws.com'
  }
};

export default awsConfig;
