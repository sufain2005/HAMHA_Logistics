const errorHandler = (err, req, res, next) => {
  console.error('Unhandled Application Error:', err);

  const statusCode = err.statusCode || 500;
  let message = err.message || 'Internal Server Error';

  if (!process.env.DATABASE_URL) {
    message = 'Database URL is not configured. Please paste your Neon database connection string in backend/.env';
  } else if (err.code === 'ECONNREFUSED' || err.message?.includes('connect ECONNREFUSED')) {
    message = 'Cannot connect to database host. Check your network or Neon connection string.';
  }

  res.status(statusCode).json({
    success: false,
    message,
    error: {
      message,
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    },
  });
};

module.exports = errorHandler;
