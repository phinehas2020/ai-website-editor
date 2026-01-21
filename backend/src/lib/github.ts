import { Octokit } from '@octokit/rest';

const octokit = new Octokit({
  auth: (process.env.GITHUB_TOKEN || '').trim(),
});

const GITHUB_ORG = (process.env.GITHUB_ORG || '').trim();

export function getOwnerAndRepo(repoName: string): { owner: string; repo: string } {
  const cleanRepoName = repoName.trim();
  if (cleanRepoName.includes('/')) {
    const [owner, repo] = cleanRepoName.split('/');
    return { owner: owner.trim(), repo: repo.trim() };
  }
  return { owner: GITHUB_ORG, repo: cleanRepoName };
}

interface FileContent {
  path: string;
  content: string;
}

interface RepoFile {
  path: string;
  content: string;
  sha: string;
}

const EDITABLE_EXTENSIONS = ['.tsx', '.ts', '.jsx', '.js', '.json', '.css', '.scss', '.html', '.md'];
const EXCLUDED_PATHS = [
  'node_modules',
  '.env',
  '.git',
  'package-lock.json',
  'next.config',
  'api/',
  '.next',
  'dist',
  'build',
];

function isEditableFile(path: string): boolean {
  const extension = '.' + path.split('.').pop()?.toLowerCase();
  const hasEditableExtension = EDITABLE_EXTENSIONS.includes(extension);
  const isExcluded = EXCLUDED_PATHS.some(excluded => path.includes(excluded));
  return hasEditableExtension && !isExcluded;
}

export async function getRepoFiles(repoName: string, branch: string = 'main'): Promise<RepoFile[]> {
  const files: RepoFile[] = [];
  const { owner, repo } = getOwnerAndRepo(repoName);

  async function fetchDirectory(path: string = '') {
    try {
      const { data } = await octokit.repos.getContent({
        owner,
        repo,
        path,
        ref: branch,
      });

      if (Array.isArray(data)) {
        for (const item of data) {
          if (item.type === 'dir') {
            if (!EXCLUDED_PATHS.some(excluded => item.path.includes(excluded))) {
              await fetchDirectory(item.path);
            }
          } else if (item.type === 'file' && isEditableFile(item.path)) {
            const fileContent = await getFileContent(repoName, item.path, branch);
            if (fileContent) {
              files.push({
                path: item.path,
                content: fileContent.content,
                sha: item.sha,
              });
            }
          }
        }
      }
    } catch (error) {
      console.error(`Error fetching directory ${path}:`, error);
    }
  }

  await fetchDirectory();
  return files;
}

export async function getFileContent(
  repoName: string,
  path: string,
  branch: string = 'main'
): Promise<{ content: string; sha: string } | null> {
  try {
    const { owner, repo } = getOwnerAndRepo(repoName);
    const { data } = await octokit.repos.getContent({
      owner,
      repo,
      path,
      ref: branch,
    });

    if ('content' in data && data.type === 'file') {
      const content = Buffer.from(data.content, 'base64').toString('utf-8');
      return { content, sha: data.sha };
    }
    return null;
  } catch (error) {
    console.error(`Error fetching file ${path}:`, error);
    return null;
  }
}

export async function createBranch(repoName: string, branchName: string, baseBranch: string = 'main'): Promise<boolean> {
  try {
    const { owner, repo } = getOwnerAndRepo(repoName);
    const { data: ref } = await octokit.git.getRef({
      owner,
      repo,
      ref: `heads/${baseBranch}`,
    });

    await octokit.git.createRef({
      owner,
      repo,
      ref: `refs/heads/${branchName}`,
      sha: ref.object.sha,
    });

    return true;
  } catch (error) {
    console.error(`Error creating branch ${branchName}:`, error);
    return false;
  }
}

export async function commitFiles(
  repoName: string,
  branchName: string,
  files: FileContent[],
  message: string
): Promise<boolean> {
  try {
    const { owner, repo } = getOwnerAndRepo(repoName);
    for (const file of files) {
      const existingFile = await getFileContent(repoName, file.path, branchName);

      if (existingFile) {
        await octokit.repos.createOrUpdateFileContents({
          owner,
          repo,
          path: file.path,
          message,
          content: Buffer.from(file.content).toString('base64'),
          branch: branchName,
          sha: existingFile.sha,
        });
      } else {
        await octokit.repos.createOrUpdateFileContents({
          owner,
          repo,
          path: file.path,
          message,
          content: Buffer.from(file.content).toString('base64'),
          branch: branchName,
        });
      }
    }

    return true;
  } catch (error) {
    console.error('Error committing files:', error);
    return false;
  }
}

export async function mergeBranch(repoName: string, branchName: string, baseBranch: string = 'main'): Promise<boolean> {
  try {
    const { owner, repo } = getOwnerAndRepo(repoName);
    await octokit.repos.merge({
      owner,
      repo,
      base: baseBranch,
      head: branchName,
      commit_message: `Merge ${branchName} into ${baseBranch}`,
    });

    return true;
  } catch (error) {
    console.error(`Error merging branch ${branchName}:`, error);
    return false;
  }
}

export async function deleteBranch(repoName: string, branchName: string): Promise<boolean> {
  try {
    const { owner, repo } = getOwnerAndRepo(repoName);
    await octokit.git.deleteRef({
      owner,
      repo,
      ref: `heads/${branchName}`,
    });

    return true;
  } catch (error) {
    console.error(`Error deleting branch ${branchName}:`, error);
    return false;
  }
}

export async function getDefaultBranch(repoName: string): Promise<string> {
  try {
    const { owner, repo } = getOwnerAndRepo(repoName);
    const { data } = await octokit.repos.get({
      owner,
      repo,
    });
    return data.default_branch;
  } catch (error) {
    console.error('Error getting default branch:', error);
    return 'main';
  }
}
