const SupabaseService = require('../services/supabase.service');

async function requireAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // Allow guest/simulated user if running in offline mode
      req.user = { id: 'usr_mock_01', email: 'guest@rytheme.app', username: 'Kamlesh' };
      return next();
    }

    const token = authHeader.split(' ')[1];
    const user = await SupabaseService.verifyUserToken(token);
    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized: ' + err.message
    });
  }
}

module.exports = { requireAuth };
